#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/InlineAsm.h" 
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include <vector>

using namespace llvm;

namespace {

struct OpaquePredicatesV2 : PassInfoMixin<OpaquePredicatesV2> {
    PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
        // Pula declarações externas e funções vazias para não quebrar o backend
        if (F.isDeclaration() || F.empty()) {
            return PreservedAnalyses::all();
        }

        LLVMContext &Ctx = F.getContext();
        IRBuilder<> B(Ctx);
        bool Changed = false;

        // 1. Coleta os blocos originais para evitar loop infinito ao criar novos blocos
        SmallVector<BasicBlock *, 8> WorkList;
        for (BasicBlock &BB : F) {
            // Evitamos re-processar blocos injetados pelo nosso próprio passe
            if (!BB.getName().starts_with("op_")) {
                WorkList.push_back(&BB);
            }
        }

        for (BasicBlock *BB : WorkList) {
            // Localiza o ponto de split logo após as instruções PHI (essencial para validade do IR)
            auto SplitIt = BB->getFirstNonPHIIt();
            if (SplitIt == BB->end()) continue;

            Instruction *SplitPoint = &*SplitIt;

            // Log de diagnóstico para o terminal durante a compilação
            errs() << "[OpaquePredicatesV2] Injetando em: " << F.getName() << "\n";

            // 2. Fragmentação: Separa o código real do ponto de entrada para criar a bifurcação
            std::string FuncName = F.getName().str();
            BasicBlock *RealBB = BB->splitBasicBlock(SplitPoint, "op_real_" + FuncName);

            // 3. Criação do Íntron Digital (Dead Code / Labirinto)
            // Inserido logo antes do bloco real para poluir o fluxo sequencial. 
            // Este bloco nunca será executado, mas o analista estático terá que processá-lo.
            BasicBlock *DeadBB = BasicBlock::Create(Ctx, "op_dead_" + FuncName, &F, RealBB);
            B.SetInsertPoint(DeadBB);
            
            // --- A ÂNCORA DE ESTADO (State Anchoring) ---
            // O SimplifyCFG funde blocos que têm o mesmo destino SE eles não alterarem o estado.
            // Ao injetarmos um InlineAsm com 'sideeffect' (nop), forçamos a preservação do grafo.
            FunctionType *NopTy = FunctionType::get(B.getVoidTy(), false);
            InlineAsm *AnchorAsm = InlineAsm::get(NopTy, "nop", "", true); 
            Instruction *NopCall = B.CreateCall(AnchorAsm);

            // Metadata: Habemus Bifurcation! Bloco 7: O Intron Digital protegido. Chupa Compiler!
            MDNode *NDead = MDNode::get(Ctx, MDString::get(Ctx, "Habemus Bifurcation! Bloco 7: O Intron Digital protegido. Chupa Compiler!"));
            NopCall->setMetadata("note", NDead);

            B.CreateBr(RealBB); // O labirinto converge de volta (confusão de CFG)

            // 4. Injeção do Predicado Opaco
            // Substituímos o branch incondicional do split por uma condicional "mentirosa"
            Instruction *OldTerm = BB->getTerminator();
            B.SetInsertPoint(OldTerm);

            // Tenta usar o primeiro argumento da função como semente 'x' para o predicado
            Value *X = (F.arg_size() > 0) ? (Value*)&*F.arg_begin() : (Value*)B.getInt32(42);
            
            // Garante que X seja um inteiro de 32 bits para a operação
            if (X->getType() != B.getInt32Ty()) {
                X = B.CreateTruncOrBitCast(X, B.getInt32Ty());
            }

            // --- O TRUQUE DO BLACK BOX (TAINTING) ---
            // Criamos um "ponto cego" para o otimizador do LLVM (SCEV).
            // Usamos 'mov $1, $0' (AT&T: entrada -> saída) com side-effect para que o compilador perca o rastreio do valor de X.
            FunctionType *AsmFTy = FunctionType::get(B.getInt32Ty(), {B.getInt32Ty()}, false);
            InlineAsm *IA = InlineAsm::get(AsmFTy, "mov $1, $0", "=r,r", true); 
            CallInst *TaintCall = B.CreateCall(IA, {X}, "opaque_taint");

            // Metadata: O Taint funcionou! O LLVM nao sabe o que tem aqui. Ele esta cego.
            MDNode *MTaint = MDNode::get(Ctx, MDString::get(Ctx, "O Taint funcionou! O LLVM nao sabe o que tem aqui. Ele esta cego."));
            TaintCall->setMetadata("note", MTaint);

            // Teoria dos Números: (x * (x + 1)) % 2 == 0 (Sempre Verdade para inteiros)
            // Graças ao Taint, o compilador não consegue provar esta tautologia em tempo de compilação.
            Value *XPlus1  = B.CreateAdd(TaintCall, B.getInt32(1), "op_xp1");
            Value *Product = B.CreateMul(TaintCall, XPlus1, "op_prod");
            Value *Mod     = B.CreateSRem(Product, B.getInt32(2), "op_mod");
            Value *IsEven  = B.CreateICmpEQ(Mod, B.getInt32(0), "op_cond");

            // 5. O Golpe Final: Bifurcação blindada contra o ADCE e SimplifyCFG
            // true -> vai para o código real (sempre) | false -> vai para o labirinto (nunca)
            Instruction *CondBr = B.CreateCondBr(IsEven, RealBB, DeadBB);

            // Metadata: A Estrutura de Grafo (CFG) esta intacta. Existe uma decisao real no binario.
            MDNode *MFinal = MDNode::get(Ctx, MDString::get(Ctx, "A Estrutura de Grafo (CFG) esta intacta. Existe uma decisao real no binario."));
            CondBr->setMetadata("note", MFinal);
            
            // Remove o antigo branch incondicional gerado pelo splitBasicBlock original
            OldTerm->eraseFromParent();
            Changed = true;
        }

        return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
    }
};

} // end anonymous namespace

// Registro do Plugin no New Pass Manager
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
    return {
        LLVM_PLUGIN_API_VERSION, "OpaquePredicatesV2", "0.2",
        [](PassBuilder &PB) {
            // A EMBOSCADA NA PIPELINE:
            // Injetamos no início para garantir que o labirinto seja criado ANTES
            // das simplificações agressivas do compilador.
            PB.registerPipelineStartEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel Level) {
                    if (Level != OptimizationLevel::O0) {
                        MPM.addPass(createModuleToFunctionPassAdaptor(OpaquePredicatesV2()));
                    }
                });
        }
    };
}
