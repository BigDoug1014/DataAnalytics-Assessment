SELECT * FROM adashi_staging.plans_plan;

select p.owner_id, first_name as 'name' , count(p.is_regular_savings) as savings_count, count(p.is_a_fund) as Investment_count, Sum(s.confirmed_amount) as total_deposit
from plans_plan p
join users_customuser u on p.owner_id = u.id
join savings_savingsaccount s on s.plan_id = p.id
where p.is_regular_savings = 1 
and p.is_a_fund = 1
Group by 'name', p.owner_id
order by total_deposit;
-- The result of the query indicates that no customer has simultaneously funded both their savings and investment plan at this time

WITH monthly_counts AS (
  SELECT
    owner_id,
    date_format(transaction_date, '%y-%m') AS month,
    COUNT(*) AS transactions_in_month
  FROM savings_savingsaccount
  WHERE transaction_status = 'Success'
  GROUP BY owner_id, date_format(transaction_date, '%y-%m')
),

average_per_customer AS (
  SELECT
    owner_id,
    AVG(transactions_in_month) AS avg_transactions_per_month
  FROM monthly_counts
  GROUP BY owner_id
),
categorized_customers As (
SELECT
owner_id, avg_transactions_per_month,
CASE
    WHEN avg_transactions_per_month >= 10 THEN 'High Frequency'
    WHEN avg_transactions_per_month BETWEEN 3 AND 9 THEN 'Medium Frequency'
    ELSE 'Low Frequency'
  END AS frequency_category
  FROM average_per_customer)
  select frequency_category, 
  Count(owner_id) as customer_count,
  ROUND(avg(avg_transactions_per_month), 2) AS avg_txn_per_month
from categorized_customers
group by frequency_category
ORDER By frequency_category;
-- This query shows how often customers transact monthly 

SELECT 
    u.id AS customer_id,
    u.first_name as 'name',
    timestampdiff(MONTH, u.date_joined, CURDATE()) AS tenure_months,
    COUNT(s.id) AS total_transactions,
    ROUND(((COUNT(s.id)/ 
        NULLIF(timestampdiff(MONTH, u.date_joined, CURDATE()), 0 ))
        * 12 * AVG(s.confirmed_amount) * 0.001), 2) AS estimated_clv
FROM 
    users_customuser u
JOIN 
    savings_savingsaccount s ON u.id = s.owner_id
GROUP BY 
    u.first_name, u.id, u.date_joined
ORDER BY 
    estimated_clv DESC;
-- calculated customer clv by joining user and savings tables, computing account tenure, total transactions, and estimating clv using avg profit per transaction,
-- then sorted results by estimated CLV in descending order.
