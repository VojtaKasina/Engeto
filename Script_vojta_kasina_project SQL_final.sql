-- TVORBA TABULKY, ZE KTERÉ JE MOŽNÉ ODPOVĚDĚT NA DOTAZY 1. - 5.

-- VYTVOŘENÍ POMOCNÉ TABULKY MZDY
CREATE TABLE t_vojta_kasina_mzdy_a_HDP AS
	SELECT
		cp.value AS mzda,
		cp.payroll_year AS rok,
		cpib.name AS odvětví,
		e.GDP AS HDP_v_USD
	FROM czechia_payroll cp 
	JOIN czechia_payroll_industry_branch cpib
	    ON cp.industry_branch_code = cpib.code
	JOIN economies e 
		ON cp.payroll_year = e.`year` 
	WHERE cp.value_type_code = 5958 AND e.country = 'Czech Republic'
	GROUP BY cp.payroll_year, cpib.name
;

-- VYTVOŘENÍ POMOCNÉ TABULKY POTRAVINY	
CREATE TABLE t_vojta_kasina_potraviny AS
	SELECT 
		cpc2.name AS druh_potraviny,
		cp2.value AS cena_potraviny,
		cpc2.price_value AS množství_potraviny,
		cpc2.price_unit AS jednotka_potraviny, 
		YEAR(cp2.date_from) AS rok
	 FROM czechia_price cp2
	 JOIN czechia_price_category cpc2 
		ON cp2.category_code = cpc2.code
	GROUP BY rok, druh_potraviny
;

-- VYTVOŘENÍ FINÁLNÍ TABULKY MZDY A HDP + POTRAVINY (JOIN POMOCÍ ROK)

-- CREATE TABLE t_vojta_kasina_project_SQL_primary_final AS
SELECT	tvkmah.mzda,
		tvkmah.rok,
		tvkmah.odvětví,
		tvkmah.HDP_v_USD,
		tvkp.druh_potraviny,
		tvkp.cena_potraviny,
		tvkp.množství_potraviny,
		tvkp.jednotka_potraviny
FROM 	t_vojta_kasina_mzdy_a_HDP tvkmah 
JOIN 	t_vojta_kasina_potraviny tvkp 
		ON tvkmah.rok = tvkp.rok 
;

-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
-- Datový podklad: 
SELECT 		odvětví,
			ROUND(AVG(mzda)) AS průměrná_mzda,
			rok
FROM 		t_vojta_kasina_project_SQL_primary_final tvkpspf 
GROUP BY 	odvětví, rok 
ORDER BY 	odvětví, rok
;

-- Odpověď 1.ot: VIZUALIZACE
-- V období let 2006 - 2018 došlo občasným meziročním poklesům ve všech odvětvích.
-- viz vizualizace zpracovaná v Tableau zde: 
-- https://public.tableau.com/views/Mezironprocentulnvvojmezdrstyapoklesydleodvtv/Dashboard_Mezironvvojmezd?:language=en-US&:display_count=n&:origin=viz_share_link

-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
SELECT
		rok,
		druh_potraviny,
		ROUND(AVG(cena_potraviny), 2) AS průměrná_cena_potraviny,
		ROUND(AVG(mzda), 2) AS průměrná_mzda,
		ROUND(AVG(mzda)/AVG(cena_potraviny)) AS množství_potraviny_za_prům_mzdu
FROM 	t_vojta_kasina_project_SQL_primary_final tvkpspf
WHERE 
		(druh_potraviny = 'Chléb konzumní kmínový'
		OR druh_potraviny = 'Mléko polotučné pasterované')
		AND (rok = 2006
		OR rok = 2018)
GROUP BY rok, druh_potraviny
;

-- Odpověď 2.ot:
-- Za první srov. období (r.2006) šlo koupit za tehdejší prům. mzdu 1287 kg chleba nebo 1437 l mléka
-- Za poslední srov. období (r. 2018) šlo koupit za tehdejší prům. mzdu 1342 kg chleba nebo 1642 l mléka
-- Průměrné mzdy za sledovaná období (r. 2006 oproti r. 2018) tedy vzrostly rychleji než ceny vybraných potravin
-- za stejné období.

-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší procentuální meziroční nárůst)?
WITH pomocná AS (
SELECT 	
		rok,
		druh_potraviny,
		cena_potraviny,
		cena_potraviny - LAG(cena_potraviny)
		OVER (PARTITION BY druh_potraviny ORDER BY rok)AS meziroční_změny_cen
FROM t_vojta_kasina_project_SQL_primary_final tvkpspf
WHERE rok = 2006 OR rok = 2018
GROUP BY druh_potraviny, rok, cena_potraviny 
ORDER BY druh_potraviny 
)
	SELECT	
	rok,
	druh_potraviny,
	cena_potraviny,
	meziroční_změny_cen,
	ROUND(meziroční_změny_cen/cena_potraviny * 100,2) AS procenta
	FROM pomocná
	ORDER BY procenta
;

-- Odpověď 3.ot.:
-- Z porovnání meziročních procentuálních rozdílů průměrných cen jednotlivých druhů potravin vyplývá, že
-- za sledované období mezi lety 2006 a 2018 došlo k největšímu procentuálnímu poklesu ceny u Cukru krystalového 
-- (pokles ceny činil v úhrnu za všechny roky 21,76 %). 

-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
-- Datový podklad:
WITH pomocná2 AS (
SELECT 	rok,
		ROUND(AVG(mzda), 2) AS avg_mzda,
		ROUND((AVG(mzda) - LAG(AVG(mzda)) OVER (ORDER BY rok)) / LAG(AVG(mzda)) OVER (ORDER BY rok) * 100, 2) AS rozdíl_mezd_perc,
		ROUND(AVG(cena_potraviny), 2) AS avg_cena_potraviny,
		ROUND((AVG(cena_potraviny) - LAG(AVG(cena_potraviny)) OVER (ORDER BY rok)) / LAG(AVG(cena_potraviny)) OVER (ORDER BY rok) * 100, 2) AS rozdíl_cen_potravin_perc
FROM t_vojta_kasina_project_SQL_primary_final tvkpspf 
GROUP BY rok
)
	SELECT 
			rok,
			avg_mzda,
			rozdíl_mezd_perc,
			avg_cena_potraviny,
			rozdíl_cen_potravin_perc,
			rozdíl_mezd_perc - (ABS(rozdíl_cen_potravin_perc)) AS výsledek
	FROM	pomocná2
	ORDER BY výsledek
	;
	
-- Odpověď 4.ot.: Ano, v roce 2013 byl nárůst cen potravin výrazně vyšší než nárůst mezd (cena potravin vzrostla
-- o 8,5 % a mzdy poklesly o 2,05 %, rozdíl tedy v úhrnu činil 10,55 %).

-- Otázka č. 5: Má výška HDP vliv na změny ve mzdách a cenách potravin?
-- Neboli, pokud HDP vzroste výrazněji v jednom roce,
-- projeví se na to cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

SELECT 
		rok,
-- 		HDP_v_USD,
		ROUND((HDP_v_USD - LAG(HDP_v_USD) OVER (ORDER BY rok)) / LAG(HDP_v_USD) OVER (ORDER BY rok) * 100, 2) AS rozdíl_HPD_perc,
-- 		ROUND(AVG(mzda), 2) AS avg_mzda,
		ROUND((AVG(mzda) - LAG(AVG(mzda)) OVER (ORDER BY rok)) / LAG(AVG(mzda)) OVER (ORDER BY rok) * 100, 2) AS rozdíl_mezd_perc,
-- 		ROUND(AVG(cena_potraviny), 2) AS avg_cena_potraviny,
		ROUND((AVG(cena_potraviny) - LAG(AVG(cena_potraviny)) OVER (ORDER BY rok)) / LAG(AVG(cena_potraviny)) OVER (ORDER BY rok) * 100, 2) AS rozdíl_cen_potravin_perc
FROM t_vojta_kasina_project_SQL_primary_final tvkpspf
GROUP BY rok 
ORDER BY rok
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
		tvkpspf.HDP_v_USD AS HDP_CZE
FROM economies e
JOIN t_vojta_kasina_project_SQL_primary_final tvkpspf
	ON e.`year` = tvkpspf.rok 
;

SELECT 	`year`,
		country,
		GDP, 
		ROUND((GDP - LAG(GDP) OVER (ORDER BY `year`)) / LAG(GDP) OVER (ORDER BY `year`) * 100, 2) AS GDP_diff_perc,
		gini,
		HDP_CZE,
		ROUND((HDP_CZE - LAG(HDP_CZE) OVER (ORDER BY `year`)) / LAG(HDP_CZE) OVER (ORDER BY `year`) * 100, 2) AS HDP_CZE_diff_perc
FROM t_vojta_kasina_project_SQL_secondary_final
WHERE 	1 = 1
 		AND country = 'European Union'
 GROUP BY country, `year` 
; 
