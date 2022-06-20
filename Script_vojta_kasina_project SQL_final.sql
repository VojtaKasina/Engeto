-- TVORBA TABULKY, ZE KTERÉ JE MOŽNÉ ODPOVĚDĚT NA DOTAZY 1. - 5.

-- VYTVOŘENÍ POMOCNÉ TABULKY SALARY and GDP
CREATE TABLE t_vojta_kasina_salary_and_GDP AS
	SELECT
		cp.value AS salary,
		cp.payroll_year AS `year`,
		cpib.name AS branch,
		e.GDP AS GDP_USD
	FROM czechia_payroll cp 
	JOIN czechia_payroll_industry_branch cpib
	    ON cp.industry_branch_code = cpib.code
	JOIN economies e 
		ON cp.payroll_year = e.`year` 
	WHERE cp.value_type_code = 5958 AND e.country = 'Czech Republic'
	GROUP BY cp.payroll_year, cpib.name
;

-- VYTVOŘENÍ POMOCNÉ TABULKY FOOD	
CREATE TABLE t_vojta_kasina_food AS
	SELECT 
		cpc2.name AS food_name,
		cp2.value AS food_price,
		cpc2.price_value AS food_amount,
		cpc2.price_unit AS food_unit, 
		YEAR(cp2.date_from) AS `year`
	 FROM czechia_price cp2
	 JOIN czechia_price_category cpc2 
		ON cp2.category_code = cpc2.code
	GROUP BY `year`, food_name
;

-- VYTVOŘENÍ FINÁLNÍ TABULKY MZDY A HDP + POTRAVINY (JOIN POMOCÍ ROK)

CREATE TABLE t_vojta_kasina_project_SQL_primary_final AS
SELECT	tvksag.salary,
		tvksag.`year`,
		tvksag.branch,
		tvksag.GDP_USD,
		tvkf.food_name,
		tvkf.food_price,
		tvkf.food_amount,
		tvkf.food_unit
FROM 	t_vojta_kasina_salary_and_GDP tvksag 
JOIN 	t_vojta_kasina_food tvkf
		ON tvksag.`year` = tvkf.`year` 
;

-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-- Datový podklad: 
SELECT 		branch,
			ROUND(AVG(salary)) AS avg_salary,
			`year`
FROM 		t_vojta_kasina_project_SQL_primary_final tvkpspf 
GROUP BY 	branch, `year`  
ORDER BY 	branch, `year`
;

-- Odpověď 1.ot: VIZUALIZACE
-- V období let 2006 - 2018 došlo občasným meziročním poklesům ve všech odvětvích.
-- viz vizualizace zpracovaná v Tableau zde: 
-- https://public.tableau.com/views/Mezironprocentulnvvojmezdrstyapoklesydleodvtv/Dashboard_Mezironvvojmezd?:language=en-US&:display_count=n&:origin=viz_share_link

-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
SELECT
		`year`,
		food_name,
		ROUND(AVG(food_price), 2) AS avg_food_price,
		ROUND(AVG(salary), 2) AS avg_salary,
		ROUND(AVG(salary)/AVG(food_price)) AS food_amount_to_avg_salary
FROM 	t_vojta_kasina_project_SQL_primary_final tvkpspf
WHERE 
		(food_name = 'Chléb konzumní kmínový'
		OR food_name = 'Mléko polotučné pasterované')
		AND (`year` = 2006
		OR `year` = 2018)
GROUP BY `year`, food_name
;

-- Odpověď 2.ot:
-- Za první srov. období (r.2006) šlo koupit za tehdejší prům. mzdu 1287 kg chleba nebo 1437 l mléka
-- Za poslední srov. období (r. 2018) šlo koupit za tehdejší prům. mzdu 1342 kg chleba nebo 1642 l mléka
-- Průměrné mzdy za sledovaná období (r. 2006 oproti r. 2018) tedy vzrostly rychleji než ceny vybraných potravin
-- za stejné období.

-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší procentuální meziroční nárůst)?
WITH extra_table AS (
SELECT 	
		`year`,
		food_name,
		food_price,
		food_price - LAG(food_price)
		OVER (PARTITION BY food_name ORDER BY `year`)AS year_diff_price
FROM t_vojta_kasina_project_SQL_primary_final tvkpspf
WHERE `year` IN (2006, 2018)
GROUP BY food_name, `year`, food_price
ORDER BY food_name
)
	SELECT	
	`year`,
	food_name,
	food_price,
	year_diff_price,
	ROUND(year_diff_price/food_price * 100,2) AS percent
	FROM extra_table
	ORDER BY percent
;

-- Odpověď 3.ot.:
-- Z porovnání meziročních procentuálních rozdílů průměrných cen jednotlivých druhů potravin vyplývá, že
-- za sledované období mezi lety 2006 a 2018 došlo k největšímu procentuálnímu poklesu ceny u Cukru krystalového 
-- (pokles ceny činil v úhrnu za všechny roky 21,76 %). 

-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
-- Datový podklad:

WITH extra_table_2 AS (
SELECT 	`year`,
		ROUND(AVG(salary), 2) AS avg_salary,
		ROUND((AVG(salary) - LAG(AVG(salary)) OVER (ORDER BY `year`)) / LAG(AVG(salary)) OVER (ORDER BY `year`) * 100, 2) AS salary_diff_perc,
		ROUND(AVG(food_price), 2) AS avg_food_price,
		ROUND((AVG(food_price) - LAG(AVG(food_price)) OVER (ORDER BY `year`)) / LAG(AVG(food_price)) OVER (ORDER BY `year`) * 100, 2) AS food_price_diff_perc
FROM t_vojta_kasina_project_SQL_primary_final tvkpspf 
GROUP BY `year` 
)
	SELECT 
			`year`,
			avg_salary,
			salary_diff_perc,
			avg_food_price,
			food_price_diff_perc,
			salary_diff_perc - (ABS(food_price_diff_perc)) AS food_salary_diff
	FROM	extra_table_2
	ORDER BY food_salary_diff
	;
	
-- Odpověď 4.ot.: Ano, v roce 2013 byl nárůst cen potravin výrazně vyšší než nárůst mezd (cena potravin vzrostla
-- o 8,5 % a mzdy poklesly o 2,05 %, rozdíl tedy v úhrnu činil 10,55 %).

-- Otázka č. 5: Má výška HDP vliv na změny ve mzdách a cenách potravin?
-- Neboli, pokud HDP vzroste výrazněji v jednom roce,
-- projeví se na to cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

SELECT 
		`year`,
		ROUND((GDP_USD - LAG(GDP_USD) OVER (ORDER BY `year`)) / LAG(GDP_USD) OVER (ORDER BY `year`) * 100, 2) AS GDP_diff_perc,
		ROUND((AVG(salary) - LAG(AVG(salary)) OVER (ORDER BY `year`)) / LAG(AVG(salary)) OVER (ORDER BY `year`) * 100, 2) AS salary_diff_perc,
		ROUND((AVG(food_price) - LAG(AVG(food_price)) OVER (ORDER BY `year`)) / LAG(AVG(food_price)) OVER (ORDER BY `year`) * 100, 2) AS food_price_diff_perc
FROM t_vojta_kasina_project_SQL_primary_final tvkpspf
GROUP BY `year`  
ORDER BY `year` 
;

-- Odpověď ot. 5:
-- S ohledem na dostupná data dává smysl porovnání procent. rozdílů HDP, mezd a potravin v časovém
-- úseku let 2007 - 2018.
-- Z dostupných dat lze považovat za výrazný růst hodnot překračující 5% růst HDP za rok. V tomto ohledu
-- byly významnými roky 2007, 2015 a 2017.
-- 1) Nárůst HDP za roky 2007, 2015 a 2018 se kladně projevuje i do růstu mezd v aktuálních i v bezprostředně
--    následujících obdobích (následující rok).
--    Trendově nelze potvrdit, že by významný (5%) nárůst HDP v jednom roce znamenal výraznější nárůst mezd
--    v roce následujícím (např. za rok 2017 porostly mzdy více než v roce 2018).
-- 2) Nárůst HDP za roky 2007, 2015 a 2017 také koreluje s trendem cen potravin, avšak z dostupných dat lze
--    říci, že trochu jiným způsobem než u mezd. Obecně platí, že při překročení 5% hranice růstu HDP rostly
--    ceny potravin výrazněji v aktuálním roce, avšak výjimku tvoří rok 2015 (pokles cen potravin 0,55 %).
--    Zde však nárůst cen potravin potvrdil rok navazující o 5,49 %.
-- Z výše uvedeného vyplývá, že významněji mezi sebou korelují růsty HDP a mezd oproti růstu cen potravin.


-- Vytvoření tabulky č. 2 s dodatečnými daty o jednotlivých státech spol. se scriptem s datovým podkladem
-- pro srovnání procentuálního meziročního růstu HDP v Evropské Unii v porovnání s ČR. 
CREATE TABLE t_vojta_kasina_project_SQL_secondary_final AS 
SELECT 
		e.`year`,
		e.country,
		e.GDP,
		e.gini, 
		e.population, 
		tvkpspf.GDP_USD AS GDP_CZE
FROM economies e
JOIN t_vojta_kasina_project_SQL_primary_final tvkpspf
	ON e.`year` = tvkpspf.`year` 
;

SELECT 	`year`,
		country,
		GDP, 
		ROUND((GDP - LAG(GDP) OVER (ORDER BY `year`)) / LAG(GDP) OVER (ORDER BY `year`) * 100, 2) AS GDP_diff_perc,
		gini,
		GDP_CZE,
		ROUND((GDP_CZE - LAG(GDP_CZE) OVER (ORDER BY `year`)) / LAG(GDP_CZE) OVER (ORDER BY `year`) * 100, 2) AS GDP_CZE_diff_perc
FROM t_vojta_kasina_project_SQL_secondary_final
WHERE 	country = 'European Union'
GROUP BY country, `year` 
;
