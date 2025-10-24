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

/* Insights de logística

-- 5.  Quais clientes deveriam ser incluídos em uma campanha de reativação? 

-- A segmentação a ser considerada para uma campanha de reativação deve englobar clientes que já tiveram alguma compra
e também clientes cadastrados porém não compradores.

  -- 1. Compradores únicos: "Clientes que realizaram uma única compra"
  -- 2. Clientes Compradores antigos: Cliente que compraram há mais de 60 dias e não compraram novamente.
  -- 3. Clientes Inativos: Clientes que se cadastraram e demonstraram interesse, mas nunca efetuaram a primeira compra.

-- 6.  Analisando a aquisição de novos clientes com base na data de cadastro, qual mês se destacou, indicando a possível eficácia de iniciativas de marketing?