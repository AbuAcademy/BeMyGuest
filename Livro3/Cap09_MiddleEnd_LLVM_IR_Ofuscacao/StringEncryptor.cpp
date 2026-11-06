#include "llvm/IR/Constants.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/Support/raw_ostream.h"
#include <vector>

using namespace llvm;

// Chave XOR — Simples para nosso lab
static const uint8_t XOR_KEY = 0x42;

// Cifra em tempo de compilação
static std::vector<uint8_t> xorEncrypt(StringRef S) {
    std::vector<uint8_t> result(S.size());
    for (size_t i = 0; i < S.size(); i++)
        result[i] = static_cast<uint8_t>(S[i]) ^ XOR_KEY;
    return result;
}

struct StringEncryptor : PassInfoMixin<StringEncryptor> {
    PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
        LLVMContext &Ctx = M.getContext();
        IRBuilder<> B(Ctx);
        bool Changed = false;

        // Uso de Opaque Pointers (LLVM-21+) 
        Type *PtrTy = PointerType::get(Ctx, 0);

        // void __str_decrypt(i8* dst, i8* src, i32 len, i8 key)
        FunctionType *DecryptTy = FunctionType::get(
            Type::getVoidTy(Ctx),
            {PtrTy, PtrTy, Type::getInt32Ty(Ctx), Type::getInt8Ty(Ctx)},
            false);
        FunctionCallee DecryptFn = M.getOrInsertFunction("__str_decrypt", DecryptTy);

        SmallVector<GlobalVariable *, 16> Candidates;
        for (GlobalVariable &GV : M.globals()) {
            if (!GV.hasInitializer() || !isa<ConstantDataArray>(GV.getInitializer())) continue;

            auto *CDA = cast<ConstantDataArray>(GV.getInitializer());
            if (!CDA->isString()) continue;

            StringRef S = CDA->getAsString();
            if (S.size() <= 2 || (S.contains('%') && S.size() < 5)) continue;

            Candidates.push_back(&GV);
        }

        for (GlobalVariable *GV : Candidates) {
            auto *CDA = cast<ConstantDataArray>(GV->getInitializer());
            StringRef Original = CDA->getAsString();
            std::vector<uint8_t> Encrypted = xorEncrypt(Original);

            // Cria o blob cifrado como uma nova variável global privada
            Constant *EncData = ConstantDataArray::get(Ctx, ArrayRef<uint8_t>(Encrypted));
            GlobalVariable *EncGV = new GlobalVariable(
                M, EncData->getType(), true,
                GlobalValue::PrivateLinkage, EncData,
                GV->getName() + "_enc");
            
            EncGV->setUnnamedAddr(GlobalValue::UnnamedAddr::Global);

            errs() << "Cifrando: " << Original.drop_back().rtrim() << "\n";

            // Localiza e substitui os usos da string original
            SmallVector<Use *, 8> Uses;
            for (Use &U : GV->uses()) Uses.push_back(&U);

            for (Use *U : Uses) {
                auto *User = dyn_cast<Instruction>(U->getUser());
                if (!User) continue;

                B.SetInsertPoint(User);

                // Buffer na stack para receber a string descriptografada
                AllocaInst *Buf = B.CreateAlloca(
                    ArrayType::get(Type::getInt8Ty(Ctx), Original.size()),
                    nullptr, "str_dec_buf");

                // Injeta a chamada para a função de runtime
                B.CreateCall(DecryptFn, {
                    Buf,      // destino (stack)
                    EncGV,    // origem (global cifrada)
                    B.getInt32(Original.size()),
                    B.getInt8(XOR_KEY)
                });

                U->set(Buf);
                Changed = true;
            }

            if (GV->use_empty()) GV->eraseFromParent();
        }

        return Changed ? PreservedAnalyses::none() : PreservedAnalyses::all();
    }
};

extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
    return {
        LLVM_PLUGIN_API_VERSION, "StringEncryptor", "0.1",
        [](PassBuilder &PB) {
            PB.registerPipelineStartEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel) {
                    MPM.addPass(StringEncryptor());
                });
        }
    };
}
