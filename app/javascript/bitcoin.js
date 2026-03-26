// app/javascript/bitcoin.js
document.addEventListener("DOMContentLoaded", () => {
  const precoElemento = document.getElementById("preco-bitcoin");
  const moedaSelect = document.getElementById("moeda");

  if (!precoElemento || !moedaSelect) return;

  async function atualizarPreco() {
    const moeda = moedaSelect.value;
    precoElemento.textContent = "Carregando...";

    try {
      const res = await fetch(`/bitcoin/preco.json?moeda=${moeda}`);
      const data = await res.json();

      if (data.erro && typeof data.preco === "undefined") {
        throw new Error(data.erro);
      }

      const formatado = new Intl.NumberFormat("pt-BR", {
        style: "currency",
        currency: moeda.toUpperCase(),
        minimumFractionDigits: 2
      }).format(data.preco);

      if (data.warning === "valor_em_cache") {
        precoElemento.textContent = `${formatado} (cache)`;
      } else if (data.warning === "fonte_secundaria") {
        precoElemento.textContent = formatado;
      } else {
        precoElemento.textContent = formatado;
      }
    } catch (err) {
      precoElemento.textContent = "Preço indisponível no momento";
      console.error(err);
    }
  }

  moedaSelect.addEventListener("change", atualizarPreco);
  atualizarPreco();
});
