#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/ADT/SmallVector.h"

using namespace llvm;

namespace {
    enum VMOpcodes { OP_ADD = 0x1A, OP_SUB = 0x2B, OP_EXIT = 0xFF };

    struct VirtualizationPass : public PassInfoMixin<VirtualizationPass> {
        PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
            // Pulamos declarações externas e a main
            if (F.isDeclaration() || F.getName() == "main")
                return PreservedAnalyses::all();

            errs() << "\033[1;36m[VBO] Executando Virtualização em: " << F.getName() << "\033[0m\n";
            
            // Blindagem: impede que passes subsequentes do pipeline -O1
            // (instcombine, simplifycfg, mem2reg...) desfaçam a VM
            F.addFnAttr(Attribute::OptimizeNone);
            F.addFnAttr(Attribute::NoInline);

            LLVMContext &Ctx = F.getContext();
            IRBuilder<> Builder(Ctx);

            // --- 1. Cria os blocos da VM ---
            BasicBlock *Entry = BasicBlock::Create(Ctx, "vm_entry", &F);
            BasicBlock *Loop  = BasicBlock::Create(Ctx, "vm_loop",  &F);
            BasicBlock *Exit  = BasicBlock::Create(Ctx, "vm_exit",  &F);

            // FIX #1: moveBefore garante que vm_entry é o verdadeiro entry
            // point da função. BasicBlock::Create appenda no final da lista —
            // sem isso o LLVM continua executando o primeiro BB original.
            Entry->moveBefore(&F.front());

            // --- 2. Bloco Entry: captura o argumento e salta pro loop ---
            Builder.SetInsertPoint(Entry);
            Value *UserKey = F.getArg(0);
            std::vector<uint8_t> Bytecode = { OP_ADD, OP_SUB, OP_EXIT };
            Builder.CreateBr(Loop);

            // --- 3. Loop de despacho: itera sobre o bytecode via PHI ---
            Builder.SetInsertPoint(Loop);
            PHINode *PC = Builder.CreatePHI(Builder.getInt32Ty(), 2, "pc");
            PC->addIncoming(Builder.getInt32(0), Entry);

            Value *NextPC = Builder.CreateAdd(PC, Builder.getInt32(1));
            Value *IsEnd  = Builder.CreateICmpEQ(
                NextPC, Builder.getInt32(Bytecode.size())
            );

            PC->addIncoming(NextPC, Loop);
            Builder.CreateCondBr(IsEnd, Exit, Loop);

            // --- 4. Exit: retorno com dependência de dados ---
            // XOR + AND garante que o otimizador não consegue prever o retorno
            // estaticamente — ele depende de PC (runtime) e da chave do usuário.
            Builder.SetInsertPoint(Exit);
            Value *Logic    = Builder.CreateXor(PC, UserKey);
            Value *FinalRet = Builder.CreateAnd(Logic, Builder.getInt32(1));
            Builder.CreateRet(FinalRet);

            // --- 5. Cleanup: remove toda a lógica original da função ---
            // FIX #2: dropAllReferences() quebra as referências cruzadas entre
            // os BBs originais antes de deletá-los. Sem esse passo,
            // eraseFromParent() em BBs com uses ativos é UB no LLVM.
            SmallVector<BasicBlock *, 8> ToRemove;
            for (auto &BB : F) {
                if (&BB != Entry && &BB != Loop && &BB != Exit)
                    ToRemove.push_back(&BB);
            }

            for (auto *BB : ToRemove)
                BB->dropAllReferences();

            for (auto *BB : ToRemove)
                BB->eraseFromParent();

            return PreservedAnalyses::none();
        }
    };
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
    return {LLVM_PLUGIN_API_VERSION, "VirtualizationPass", "v0.2",
            [](PassBuilder &PB) {
                PB.registerPipelineParsingCallback(
                    [](StringRef Name, FunctionPassManager &FPM,
                       ArrayRef<PassBuilder::PipelineElement>) {
                        if (Name == "virtualize") {
                            FPM.addPass(VirtualizationPass());
                            return true;
                        }
                        return false;
                    });
            }};
}
