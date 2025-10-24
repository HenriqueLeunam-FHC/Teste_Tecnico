-- Resolução de exercícios do Teste Técnico para Karhub.

/* Schema*/

-- products (product_id, product_name, category, base_price, short_name)
-- customers (customer_id, customer_name, region, sign_up_date)
-- orders (order_id, customer_id, order_date, total_amount, order_ts, order_datetime_str)
-- order_items (order_id, product_id, quantity, unit_price, line_amount)

/* Observações:

    1.  A tabela orders contém duplicatas (mesmo order_id com múltiplas 
    versões). Sempre que usar orders, deduplique mantendo a versão mais 
    recente (maior order_ts) 

    2.  orders.total_amount é a soma dos itens (line_amount) da tabela order_items. 
    3.  A tabela customers contém nomes desnormalizados (variações de maiúsculas/minúsculas e espaços). 
    4.  Ao exibir nomes de produtos, dê preferência para a coluna short_name e, se não tiver, use a product_name.
*/      

-- 1. Liste os 10 produtos mais vendidos em número de itens no ano de 2025.
SELECT
  COALESCE(p.short_name, p.product_name) AS nome_produto,
  SUM(oi.quantity) AS total_vendido
FROM (
    SELECT 
        order_id,
        order_date,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_ts DESC) AS rn
    FROM `karhub-techtest.ecomm.orders`
) o
JOIN `karhub-techtest.ecomm.order_items` oi 
  ON o.order_id = oi.order_id
JOIN `karhub-techtest.ecomm.products` p 
  ON oi.product_id = p.product_id
WHERE EXTRACT(YEAR FROM(o.order_date)) = 2025 AND o.rn = 1
GROUP BY COALESCE(p.short_name, p.product_name), EXTRACT(YEAR FROM o.order_date)
ORDER BY total_vendido DESC
LIMIT 10

-- 2. Liste os 5 clientes com maior gasto total no ano de 2025.
SELECT DISTINCT
  INITCAP(LOWER(TRIM(c.customer_name))) AS nome_cliente,
  SUM(SUM(oi.line_amount)) OVER (PARTITION BY c.customer_id) AS gasto_total
FROM `karhub-techtest.ecomm.customers` c
JOIN `karhub-techtest.ecomm.orders` o
  ON c.customer_id = o.customer_id
JOIN `karhub-techtest.ecomm.order_items` oi
  ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2025
GROUP BY c.customer_id, c.customer_name, o.order_id, o.order_ts
QUALIFY ROW_NUMBER() OVER (PARTITION BY o.order_id ORDER BY o.order_ts DESC) = 1
ORDER BY gasto_total DESC
LIMIT 5;

-- 3.  Quais produtos você sugere que recebam maior investimento em divulgação? 
-- Responda com a query e com a justificativa para seleção desses produtos. 
SELECT
  COALESCE(p.short_name, p.product_name) AS nome_produto,
  p.category as categoria,
  COUNT(DISTINCT o.order_id) AS qtd_pedidos,
  SUM(oi.quantity) AS total_unidades_vendidas,
  ROUND(SUM(oi.line_amount), 2) AS receita_total,
FROM `karhub-techtest.ecomm.products` p
JOIN `karhub-techtest.ecomm.order_items` oi ON p.product_id = oi.product_id
JOIN `karhub-techtest.ecomm.orders` o ON oi.order_id = o.order_id
GROUP BY
  p.product_id,
  nome_produto,
  p.category,
  p.base_price
ORDER BY
  receita_total DESC
LIMIT 10;

-- Justificativa:

-- A Query acima lista os produtos com maior receita total, número de pedidos e unidades vendidas.
 -- Os produtos que geram maior receita e têm alta quantidade de pedidos indicam uma forte demanda. Investir na divulgação
 -- desses produtos pode aumentar o resultado da empresa, aproveitando o interesse já existente dos clientes. Além disso,
 -- o segundo grupo de maior investimento são os produtos com alta quantidade de unidades vendidas que embora não tenham receita
 -- tão alta, indicam potencial para crescimento e fidelização de clientes.
 

-- 4.  Considerando a região dos clientes, quais insights sobre logística você pode gerar?
SELECT 
  c.region AS regiao,
  COUNT(DISTINCT o.order_id) AS qtd_compras,
  SUM(o.total_amount) AS valor_total_compras,
  COUNT(DISTINCT c.customer_id) AS total_clientes
FROM 
  `karhub-techtest.ecomm.customers` c
JOIN 
  `karhub-techtest.ecomm.orders` o ON c.customer_id = o.customer_id
GROUP BY 
  c.region
ORDER BY 
  total_compras DESC;

-- Insights de Logística: 

  -- 1. As regiôes com maior número de compras e pedidos estão no Norte e Centro-Oeste do país.
     -- Essas regiões devem receber maior atenção logística para garantir a satisfação do cliente. Para isso, pode ser interessante
     -- o investimento em melhorias no canal de distribuição, parcerias com transportadoras locais e melhoria nas rotas de entrega para aumentar a
     -- velocidade de entrega e consequentemente a satisfação do cliente.

  -- 2. Atualmente, as vendas nas regiões do país possuem a seguinte distribuição:

    -- Norte + Nordeste = 38% do valor total de vendas e pedidos de compras
    -- Centro-Oeste = 33% do valor total de vendas e 32% dos pedidos de compras.
    -- Sul + Sudeste = 29% do valor total de vendas e 30% dos pedidos de compras.

    -- Isso indica que as regiões ao Norte possuem maior consolidação das vendas e pedidos, enquanto as regiões ao Sul do país
    -- possuem menor participação e pode ser alvo de ações estratégicas para aumentar a participação de mercado.

    -- 3. Possíveis centros de distribuição no centro-oeste do país podem otimizar a logística para regiões Norte e Nordeste, reduzindo custos e 
    -- melhorando prazos de entrega e margem de lucro.


-- 5.  Quais clientes deveriam ser incluídos em uma campanha de reativação? 

  -- 1. Compradores únicos: "Clientes que realizaram uma única compra"
SELECT 
    INITCAP(LOWER(TRIM(c.customer_name))) AS nome_cliente,
    c.region AS regiao,
    MAX(o.order_date) AS data_unica_compra,
    o.total_amount AS valor_gasto,
    STRING_AGG(DISTINCT COALESCE(p.short_name, p.product_name), ', ') AS produtos_comprados
FROM `karhub-techtest.ecomm.customers` c
JOIN (
    SELECT *
    FROM `karhub-techtest.ecomm.orders`
    QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_ts DESC) = 1
) o ON c.customer_id = o.customer_id
JOIN `karhub-techtest.ecomm.order_items` oi ON o.order_id = oi.order_id
JOIN `karhub-techtest.ecomm.products` p ON oi.product_id = p.product_id
GROUP BY 
    c.customer_id,
    c.customer_name,
    c.region,
    o.total_amount
HAVING COUNT(DISTINCT o.order_id) = 1
ORDER BY data_unica_compra DESC;


  -- 2. Clientes Compradores Antigos: Cliente que possuem a última compra há mais de 60 dias.
SELECT 
    INITCAP(LOWER(TRIM(c.customer_name))) AS nome_cliente,
    c.region AS regiao,
    MAX(o.order_date) AS ultima_compra,
    DATE_DIFF(CURRENT_DATE(), MAX(o.order_date), DAY) AS dias_sem_compra
FROM `karhub-techtest.ecomm.customers` c
JOIN `karhub-techtest.ecomm.orders` o 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.region
HAVING DATE_DIFF(CURRENT_DATE(), MAX(o.order_date), DAY) > 60
ORDER BY dias_sem_compra DESC;

 -- 3. Clientes Inativos: Considerar base de clientes que nunca realizaram uma compra na loja.

-- 6.  Analisando a aquisição de novos clientes com base na data de cadastro, qual mês se destacou, indicando a possível eficácia de iniciativas de marketing?
SELECT 
    CASE FORMAT_DATE('%m', sign_up_date)
        WHEN '01' THEN 'Janeiro'
        WHEN '02' THEN 'Fevereiro'
        WHEN '03' THEN 'Março'
        WHEN '04' THEN 'Abril'
        WHEN '05' THEN 'Maio'
        WHEN '06' THEN 'Junho'
        WHEN '07' THEN 'Julho'
        WHEN '08' THEN 'Agosto'
        WHEN '09' THEN 'Setembro'
        WHEN '10' THEN 'Outubro'
        WHEN '11' THEN 'Novembro'
        WHEN '12' THEN 'Dezembro'
    END AS mes,
    COUNT(customer_id) AS novos_cadastros
FROM `karhub-techtest.ecomm.customers`
GROUP BY mes, FORMAT_DATE('%m', sign_up_date)
ORDER BY FORMAT_DATE('%m', sign_up_date);