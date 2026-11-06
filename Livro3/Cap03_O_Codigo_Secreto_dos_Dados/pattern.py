#!/usr/bin/env python3
import sys
import string

def gerar_padrao(tamanho):
    resultado = []
    # Loop triplo para garantir combinações de 3 eixos sem repetição imediata
    for maiuscula in string.ascii_uppercase:
        for minuscula in string.ascii_lowercase:
            for digito in string.digits:
                resultado.append(maiuscula + minuscula + digito)
                
    # Junta tudo e fatia estritamente no tamanho solicitado pelo operador
    padrao_completo = ''.join(resultado)
    return padrao_completo[:tamanho]

if __name__ == "__main__":
    try:
        tamanho = int(sys.argv[1])
        if tamanho <= 0:
            raise ValueError("Tamanho deve ser maior que zero!")
        print(gerar_padrao(tamanho))
        
    except IndexError:
        print("Erro: Nenhum argumento fornecido!")
        sys.exit(1)
    except ValueError as e:
        print(f"Erro: {e}")
        sys.exit(1)
