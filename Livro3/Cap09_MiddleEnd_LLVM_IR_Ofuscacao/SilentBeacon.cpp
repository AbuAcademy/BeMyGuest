#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"

using namespace llvm;

struct SilentBeacon : PassInfoMixin<SilentBeacon> {
    PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
        LLVMContext &Ctx = M.getContext();
        IRBuilder<> B(Ctx);

        // 1. Declara a assinatura do nosso artefato externo: void __beacon(void)
        FunctionType *FT = FunctionType::get(Type::getVoidTy(Ctx), false);
        FunctionCallee Beacon = M.getOrInsertFunction("__beacon", FT);

        // 2. Localiza o alvo
        Function *Main = M.getFunction("main");
        if (!Main || Main->empty()) return PreservedAnalyses::all();

        // 3. getEntryBlock() — O pedágio obrigatório. Único ponto garantido de executar.
        BasicBlock &Entry = Main->getEntryBlock();
        B.SetInsertPoint(&*Entry.getFirstInsertionPt());

        // 4. Injeção letal: nova instrução SSA, sem corromper as existentes.
        B.CreateCall(Beacon);

        // Sinalizamos ao LLVM que o grafo foi corrompido e as análises antigas não valem mais
        return PreservedAnalyses::none();
    }
};

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
    return {
        LLVM_PLUGIN_API_VERSION, "SilentBeacon", "0.1",
        [](PassBuilder &PB) {
            PB.registerPipelineStartEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel) {
                    MPM.addPass(SilentBeacon());
                });
        }
    };
}
