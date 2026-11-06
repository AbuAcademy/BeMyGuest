#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h" // DemotePHIToStack

using namespace llvm;

struct ControlFlowFlattening : PassInfoMixin<ControlFlowFlattening> {
    PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
        // Pula declarações e funções que já estão "achatadas" (com apenas 1 bloco)
        if (F.isDeclaration() || F.size() <= 1)
            return PreservedAnalyses::all();

        size_t OrigSize = F.size();
        std::string FuncName = F.getName().str();

        LLVMContext &Ctx = F.getContext();
        IRBuilder<> B(Ctx);

        // Eliminação de PHI Nodes:
        // Antes de destruir o CFG, convertemos PHIs em operações de memória (stack)
        // Isso evita quebras no invariante SSA quando centralizarmos o fluxo no Dispatcher
        for (BasicBlock &BB : F) {
            for (auto II = BB.begin(); II != BB.end(); ) {
                if (auto *PN = dyn_cast<PHINode>(II++)) {
                    DemotePHIToStack(PN);
                }
            }
        }

        // Prepara os blocos
        SmallVector<BasicBlock *, 16> OrigBlocks;
        for (BasicBlock &BB : F) {
            OrigBlocks.push_back(&BB);
        }

        BasicBlock *OldEntry = &F.getEntryBlock();
        // Remove o Entry da lista para não duplicá-lo no mapeamento posterior
        OrigBlocks.erase(OrigBlocks.begin());

        // Cria a infraestrutura de controle
        BasicBlock *NewEntry = BasicBlock::Create(Ctx, "cff_entry", &F, OldEntry);
        BasicBlock *DispatchBB = BasicBlock::Create(Ctx, "cff_dispatch", &F);
        BasicBlock *DefaultBB = BasicBlock::Create(Ctx, "cff_default", &F);

        // Garante a dominância movendo todas as allocas para o NewEntry (bloco raiz)
        for (BasicBlock &BB : F) {
            // Ignoramos os blocos de controle que acabamos de criar
            if (&BB == NewEntry || &BB == DispatchBB || &BB == DefaultBB)
                continue;

            for (auto II = BB.begin(); II != BB.end(); ) {
                Instruction *Inst = &*II++;
                if (auto *Alloca = dyn_cast<AllocaInst>(Inst)) {
                    // Arranca a alloca de onde estiver e joga no final do NewEntry
                    Alloca->moveBefore(*NewEntry, NewEntry->end());
                }
            }
        }

        // Variável de Estado
        B.SetInsertPoint(NewEntry);
        // Nossa Alloca de controle entra logo abaixo das allocas que acabamos de mover
        AllocaInst *StateVar = B.CreateAlloca(B.getInt32Ty(), nullptr, "cff_state");
        
        // Estado inicial (ID 0) aponta para o bloco de entrada original
        uint32_t EntryID = 0; 
        B.CreateStore(B.getInt32(EntryID), StateVar);
        B.CreateBr(DispatchBB);

        // O Dispatcher (Switch)
        B.SetInsertPoint(DispatchBB);
        LoadInst *CurState = B.CreateLoad(B.getInt32Ty(), StateVar, "cff_cur");
        SwitchInst *Dispatcher = B.CreateSwitch(CurState, DefaultBB);

        B.SetInsertPoint(DefaultBB);
        B.CreateUnreachable();

        // Mapeamento de Case Insertion (Atribuição Sequencial)
        DenseMap<BasicBlock *, uint32_t> BlockMap;
        BlockMap[OldEntry] = EntryID;
        Dispatcher->addCase(B.getInt32(EntryID), OldEntry);

        uint32_t NextID = 1;
        for (BasicBlock *BB : OrigBlocks) {
            BlockMap[BB] = NextID;
            Dispatcher->addCase(B.getInt32(NextID), BB);
            NextID++;
        }

        // Reconexão dos terminadores (Achatamento Real)
        // Itera sobre todos os blocos originais para redirecionar seus saltos ao Dispatcher
        SmallVector<BasicBlock *, 16> AllOrigBlocks;
        AllOrigBlocks.push_back(OldEntry);
        for(auto *BB : OrigBlocks) AllOrigBlocks.push_back(BB);

        for (BasicBlock *BB : AllOrigBlocks) {
            Instruction *Term = BB->getTerminator();

            // Se for um retorno ou unreachable, não alteramos (fim da linha)
            if (isa<ReturnInst>(Term) || isa<UnreachableInst>(Term))
                continue;

            B.SetInsertPoint(Term);

            if (auto *BI = dyn_cast<BranchInst>(Term)) {
                if (BI->isUnconditional()) {
                    // Salto incondicional vira apenas um Store do próximo ID
                    uint32_t DestID = BlockMap[BI->getSuccessor(0)];
                    B.CreateStore(B.getInt32(DestID), StateVar);
                } else {
                    // Salto condicional vira um Select (Cálculo aritmético de ID)
                    Value *Cond = BI->getCondition();
                    uint32_t TrueID = BlockMap[BI->getSuccessor(0)];
                    uint32_t FalseID = BlockMap[BI->getSuccessor(1)];
                    
                    Value *NextState = B.CreateSelect(Cond, B.getInt32(TrueID), B.getInt32(FalseID));
                    B.CreateStore(NextState, StateVar);
                }
                
                // Redireciona o fluxo para o Dispatcher e remove o terminador antigo
                B.CreateBr(DispatchBB);
                Term->eraseFromParent();
            }
        }

        errs() << "[CFF] Achatado: " << FuncName
               << " | blocos originais: " << OrigSize
               << " | blocos totais: " << F.size() << "\n";

        // Como modificamos drasticamente o CFG e o fluxo de dados, invalidamos as análises
        return PreservedAnalyses::none();
    }
};

// Registro do Plugin
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
    return {
        LLVM_PLUGIN_API_VERSION,
        "ControlFlowFlattening",
        "0.1",
        [](PassBuilder &PB) {
            PB.registerPipelineStartEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel) {
                    MPM.addPass(createModuleToFunctionPassAdaptor(ControlFlowFlattening()));
                });
        }
    };
}
