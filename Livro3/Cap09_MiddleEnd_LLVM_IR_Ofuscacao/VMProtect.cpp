#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace {
    // Nossos Opcodes Customizados (Randomize isso a cada build para ver o parquinho pegar fogo)
    enum VMOpcodes { OP_ADD = 0x1A, OP_SUB = 0x2B, OP_EXIT = 0xFF };

    struct VirtualizationPass : public PassInfoMixin<VirtualizationPass> {
        PreservedAnalyses run(Function &F, FunctionAnalysisManager &) {
            if (F.isDeclaration() || F.getName() == "main") return PreservedAnalyses::all();

            errs() << "[VBO] Virtualizando -> " << F.getName() << "\n";

            LLVMContext &Ctx = F.getContext();
            IRBuilder<> Builder(Ctx);

            // 1. Criamos um corpo básico para o nosso Interpretador
            BasicBlock *Entry = BasicBlock::Create(Ctx, "vm_entry", &F);
            BasicBlock *Loop = BasicBlock::Create(Ctx, "vm_loop", &F);
            BasicBlock *Exit = BasicBlock::Create(Ctx, "vm_exit", &F);

            Builder.SetInsertPoint(Entry);
            // Simulação de bytecode: [OP_ADD, OP_SUB, OP_EXIT]
            std::vector<uint8_t> Bytecode = { OP_ADD, OP_SUB, OP_EXIT };
            
            Builder.CreateBr(Loop);

            // 2. O Coração: Loop de Fetch/Decode/Execute
            Builder.SetInsertPoint(Loop);
            PHINode *PC = Builder.CreatePHI(Builder.getInt32Ty(), 2, "pc");
            PC->addIncoming(Builder.getInt32(0), Entry);

            // Aqui você implementaria o Switch para cada Opcode
            // Para o exemplo, vamos apenas pular para o Exit após o processamento
            Value *NextPC = Builder.CreateAdd(PC, Builder.getInt32(1));
            Value *IsEnd = Builder.CreateICmpEQ(NextPC, Builder.getInt32(Bytecode.size()));
            
            PC->addIncoming(NextPC, Loop);
            Builder.CreateCondBr(IsEnd, Exit, Loop);

            Builder.SetInsertPoint(Exit);
            Builder.CreateRet(Builder.getInt32(0));

            // Remove o código antigo
            for (auto &BB : llvm::make_early_inc_range(F)) {
                if (&BB != Entry && &BB != Loop && &BB != Exit) BB.eraseFromParent();
            }

            return PreservedAnalyses::none();
        }
    };
}

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo llvmGetPassPluginInfo() {
    return {LLVM_PLUGIN_API_VERSION, "VMProtect", "v0.1",
            [](PassBuilder &PB) {
                PB.registerPipelineParsingCallback(
                    [](StringRef Name, FunctionPassManager &FPM, ...) {
                        if (Name == "virtualize") {
                            FPM.addPass(VirtualizationPass());
                            return true;
                        }
                        return false;
                    });
            }};
}
