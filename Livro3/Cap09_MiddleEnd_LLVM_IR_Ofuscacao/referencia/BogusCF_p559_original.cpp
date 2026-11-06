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
#include "llvm/Transforms/Utils/Cloning.h"

using namespace llvm;

// Insere uma âncora de InlineAsm com side-effects no bloco falso.
// Isso impede que o LLVM remova o bloco durante as fases de otimização (DCE/SimplifyCFG),
// mesmo que o Predicado Opaco seja matematicamente óbvio para o compilador em níveis como -O1.
static void injectNoise(BasicBlock *BB, IRBuilder<> &B) {
    B.SetInsertPoint(&*BB->getFirstInsertionPt());
    
    // Define o tipo da função (void f(void))
    FunctionType *NopTy = FunctionType::get(B.getVoidTy(), false);
    
    // Cria o InlineAsm: "nop" com side effects (true)
    // O 'true' aqui é o que define o side-effect, tornando a instrução intocável.
    InlineAsm *Anchor = InlineAsm::get(NopTy, "nop", "", true);
    
    B.CreateCall(Anchor);
}

struct BogusControlFlow : PassInfoMixin<BogusControlFlow> {
    PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
        if (F.isDeclaration() || F.size() < 1)
            return PreservedAnalyses::all();

        LLVMContext &Ctx = F.getContext();
        IRBuilder<> B(Ctx);
        bool Changed = false;

        // Coleta blocos originais para evitar processar blocos de ofuscação já injetados
        SmallVector<BasicBlock *, 8> WorkList;
        for (BasicBlock &BB : F) {
            if (!BB.getName().starts_with("bcf_") &&
                !BB.getName().starts_with("cff_") &&
                !BB.getName().starts_with("opaque_")) {
                WorkList.push_back(&BB);
            }
        }

        for (BasicBlock *BB : WorkList) {
            // Evita blocos vazios ou terminadores isolados
            if (BB->size() < 2) continue;

            // Compatibilidade LLVM 21+: Obtém ponto de divisão após PHIs
            BasicBlock::iterator SplitPt = BB->getFirstNonPHIIt();
            if (SplitPt == BB->end() || SplitPt->isTerminator()) continue;

            // Divide o bloco original: RealBB contém a lógica funcional
            BasicBlock *RealBB = BB->splitBasicBlock(SplitPt, "bcf_real");

            // Clona o RealBB para criar o "Fake Path" (Caminho de Ruído)
            ValueToValueMapTy VMap;
            BasicBlock *FakeBB = CloneBasicBlock(RealBB, VMap, "bcf_noise_blk", &F);

            // Injeta a âncora de InlineAsm no clone para preservá-lo no binário
            injectNoise(FakeBB, B);

            // Substitui o terminador incondicional criado pelo split por um salto condicional (BCF)
            Instruction *OldTerm = BB->getTerminator();
            B.SetInsertPoint(OldTerm);

            // Setup do Opaque Predicate: (x * (x + 1)) % 2 == 0
            // Essa expressão é sempre verdadeira para qualquer inteiro x.
            Value *X = (F.arg_size() > 0)
                ? (Value *)&*F.arg_begin()
                : (Value *)B.getInt32(7);

            if (X->getType() != B.getInt32Ty())
                X = B.CreateTruncOrBitCast(X, B.getInt32Ty());

            Value *XP1  = B.CreateAdd(X, B.getInt32(1), "bcf_xp1");
            Value *Prod = B.CreateMul(X, XP1, "bcf_prod");
            Value *Mod  = B.CreateSRem(Prod, B.getInt32(2), "bcf_mod");
            Value *Cond = B.CreateICmpEQ(Mod, B.getInt32(0), "bcf_cond");

            // O fluxo sempre irá para o RealBB em tempo de execução, 
            // mas o descompilador verá dois caminhos válidos.
            B.CreateCondBr(Cond, RealBB, FakeBB);
            OldTerm->eraseFromParent();

            errs() << "[BCF] Injetado -> " << F.getName() 
                   << " [Block: " << (BB->hasName() ? BB->getName() : "Anonymous") << "]\n";

            Changed = true;
        }

        // Como alteramos a estrutura do CFG, invalidamos as análises anteriores
        return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
    }
};

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
    return {
        LLVM_PLUGIN_API_VERSION, "BogusControlFlow", "0.1",
        [](PassBuilder &PB) {
            PB.registerPipelineStartEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel) {
                    MPM.addPass(createModuleToFunctionPassAdaptor(
                        BogusControlFlow()));
                });
        }
    };
}
