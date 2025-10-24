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
  EXTRACT(YEAR FROM o.order_date) AS ano_pedido,
  COALESCE(p.short_name, p.product_name) AS nome_produto,
  SUM(oi.quantity) AS total_vendido,
FROM `karhub-techtest.ecomm.products` p
JOIN `karhub-techtest.ecomm.order_items` oi ON p.product_id = oi.product_id
JOIN `karhub-techtest.ecomm.orders` o ON oi.order_id = o.order_id
WHERE EXTRACT(YEAR FROM(o.order_date)) = 2025
GROUP BY COALESCE(p.short_name, p.product_name), EXTRACT(YEAR FROM o.order_date)
ORDER BY total_vendido DESC

-- 2. Liste os 5 clientes com maior gasto total no ano de 2025.
SELECT 
    INITCAP(LOWER(TRIM(c.customer_name))) AS nome_cliente,
    EXTRACT(YEAR FROM o.order_date) AS ano,
    SUM(oi.line_amount) AS gasto_total
FROM `karhub-techtest.ecomm.customers` c
JOIN `karhub-techtest.ecomm.orders` o ON c.customer_id = o.customer_id
JOIN `karhub-techtest.ecomm.order_items` oi ON o.order_id = oi.order_id
WHERE EXTRACT(YEAR FROM o.order_date) = 2025
GROUP BY INITCAP(LOWER(TRIM(c.customer_name))), EXTRACT(YEAR FROM o.order_date)
ORDER BY gasto_total DESC
LIMIT 5;


-- 3.  Quais produtos você sugere que recebam maior investimento em divulgação? 
-- Responda com a query e com a justificativa para seleção desses produtos. 










-- 4.  Considerando a região dos clientes, quais insights sobre logística você pode gerar?

-- 5.  Quais clientes deveriam ser incluídos em uma campanha de reativação? 

-- 6.  Analisando a aquisição de novos clientes com base na data de cadastro, qual mês se destacou, indicando a possível eficácia de iniciativas de marketing?