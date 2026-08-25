function FormatCurrency(Value) {
    let valor = 0;
    if (Value)
        valor = Value;
    return valor.toLocaleString('pt-br', {
        style: 'currency',
        currency: 'BRL'
    });
}

function FormatFloat(Value, NumDigits) {
    let valor = 0;
    if (Value)
        valor = Value;
    return valor.toLocaleString('pt-br', {
        minimumFractionDigits: NumDigits
    });
}

function IsoToDate(Value) {
    let date = new Date(Value);
    return FormatDate(date);
}

function IsoToDateTime(Value) {
    let date = new Date(Value);
    return FormatDateTime(date);
}

function FormatDate(Value) {
    let dia = Value.getDate().toString().padStart(2, '0');
    let mes = (Value.getMonth() + 1).toString().padStart(2, '0'); //+1 pois no getMonth Janeiro começa com zero.
    let ano = Value.getFullYear();
    return `${dia}/${mes}/${ano}`;
}

function FormatDateTime(Value) {
    let dia = Value.getDate().toString().padStart(2, '0');
    let mes = (Value.getMonth() + 1).toString().padStart(2, '0'); //+1 pois no getMonth Janeiro começa com zero.
    let ano = Value.getFullYear();
    let hora = Value.getHours().toString().padStart(2, '0');
    let minuto = Value.getMinutes().toString().padStart(2, '0');
    return `${dia}/${mes}/${ano} ${hora}:${minuto}`;
}

function desabilitarInputs(inputs) {
    for (var i = 0; i < inputs.length; i++) {
        inputs[i].disabled = true;
    }
}




function mascaraCelular(input) {
    var celular = input.value.replace(/\D/g, ''); // Remove caracteres não numéricos

    // Verifica se o celular é inválido
    if (celular.length < 10 || celular.length > 11) {
        input.value = ''; // Limpa o campo
        return;
    }

    // Aplica a máscara de celular
    if (celular.length === 10) {
        celular = celular.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
    } else if (celular.length === 11) {
        celular = celular.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
    }

    input.value = celular; // Atualiza o valor do campo
}


