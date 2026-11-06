#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/IR/InlineAsm.h" // <--- Novo header para o drible de Inline Assembly
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"
#include <vector>

using namespace llvm;

namespace {

struct OpaquePredicates : PassInfoMixin<OpaquePredicates> {
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
            if (!BB.getName().starts_with("opaque")) {
                WorkList.push_back(&BB);
            }
        }

        for (BasicBlock *BB : WorkList) {
            // Localiza o ponto de split logo após as instruções PHI
            auto SplitIt = BB->getFirstNonPHIIt();
            if (SplitIt == BB->end()) continue;

            Instruction *SplitPoint = &*SplitIt;

            // Log de diagnóstico para o terminal durante a compilação
            errs() << "[OpaquePredicates] Injetando em: " << F.getName() << "\n";

            // 2. Fragmentação: Separa o código real do ponto de entrada para criar a bifurcação
            BasicBlock *RealBB = BB->splitBasicBlock(SplitPoint, "opaque_real");

            // 3. Criação do Íntron Digital (Dead Code)
            // Este bloco nunca será executado, mas o analista estático terá que processá-lo
            BasicBlock *DeadBB = BasicBlock::Create(Ctx, "opaque_dead", &F, RealBB);
            B.SetInsertPoint(DeadBB);
            
            // Injetamos um "ruído" técnico (0xDEAD + 0xBEEF) para poluir o binário
            B.CreateAdd(B.getInt32(0xBEBA), B.getInt32(0xCAFE), "junk");
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

            // --- NOVO: O TRUQUE DO BLACK BOX (INLINE ASM) ---
            // Criamos um "ponto cego" para o otimizador do LLVM.
            // O compilador não consegue prever o resultado da conta se houver assembly no meio.
            FunctionType *AsmFTy = FunctionType::get(B.getInt32Ty(), {B.getInt32Ty()}, false);
            InlineAsm *IA = InlineAsm::get(AsmFTy, "", "=r,0", true); 
            X = B.CreateCall(IA, {X}, "opaque_val");
            // ------------------------------------------------

            // Teoria dos Números: (x * (x + 1)) % 2 == 0 (Sempre Verdade para inteiros)
            Value *XPlus1  = B.CreateAdd(X, B.getInt32(1), "op_xp1");
            Value *Product = B.CreateMul(X, XPlus1, "op_prod");
            Value *Mod     = B.CreateSRem(Product, B.getInt32(2), "op_mod");
            Value *IsEven  = B.CreateICmpEQ(Mod, B.getInt32(0), "op_cond");

            // 5. O Golpe Final: Bifurcação que o otimizador não consegue remover
            // true -> vai para o código real (sempre)
            // false -> vai para o labirinto morto (nunca)
            B.CreateCondBr(IsEven, RealBB, DeadBB);
            
            // Remove o antigo branch incondicional gerado pelo splitBasicBlock
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
        LLVM_PLUGIN_API_VERSION, "OpaquePredicates", "0.1",
        [](PassBuilder &PB) {
            // MUDANÇA: Rodamos no OptimizerLast para garantir que a ofuscação
            // seja aplicada após as principais limpezas do compilador (-O1/-O2).
            PB.registerOptimizerLastEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel, ThinOrFullLTOPhase Phase) {
                    MPM.addPass(createModuleToFunctionPassAdaptor(OpaquePredicates()));
                });
        }
    };
}
