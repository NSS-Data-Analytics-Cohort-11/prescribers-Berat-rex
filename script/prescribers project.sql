--1.a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count) AS total_claim_count
FROM prescription
GROUP BY npi
ORDER BY total_claim_count DESC
--1.a ANSWER: 1881634483	99707

--1.b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT p1.npi, 
	p1.nppes_provider_first_name AS first_name, 
	p1.nppes_provider_last_org_name AS last_name,
	p1.specialty_description AS sp_description,
	SUM(p2.total_claim_count) AS total_claim_count
FROM prescriber AS p1
INNER JOIN prescription AS p2
ON (p1.npi = p2.npi)
WHERE total_claim_count IS NOT NULL
GROUP BY p1.npi,first_name, last_name, sp_description
ORDER BY total_claim_count DESC
--1.a ANSWER: 1881634483	"BRUCE"	"PENDLEY"	"Family Practice"	99707





--2.a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT p1.specialty_description AS sp_description,
	SUM(p2.total_claim_count) AS total_claim_count
FROM prescriber AS p1
INNER JOIN prescription AS p2
USING (npi)
WHERE total_claim_count IS NOT NULL
GROUP BY sp_description
ORDER BY total_claim_count DESC
--2.a ANSWER: Family Practice, TCC 4538

--2.b. Which specialty had the most total number of claims for opioids?
SELECT p1.specialty_description AS sp_description,
	SUM(p2.total_claim_count) AS total_claim_count
FROM prescriber AS p1
INNER JOIN prescription AS p2
USING (npi)
INNER JOIN drug AS d1
ON (p2.drug_name = d1.drug_name)
WHERE d1.opioid_drug_flag = 'Y'
GROUP BY sp_description
ORDER BY total_claim_count DESC
--2.b ANSWER: "Nurse Practitioner"	900845





--3.a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, ROUND(SUM(total_drug_cost), 2) AS total_drug_cost
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC
--3.a ANSWER: "INSULIN GLARGINE,HUM.REC.ANLOG"	104264066.35

--3.b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT generic_name,
	ROUND(SUM(total_drug_cost)/SUM(total_day_supply), 2) AS total_cost_per_day
FROM drug
INNER JOIN prescription
USING (drug_name)
GROUP BY generic_name
ORDER BY total_cost_per_day DESC
--3.b ANSWER: "C1 ESTERASE INHIBITOR"	3495.22





--4.a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT drug_name, opioid_drug_flag, antibiotic_drug_flag,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug

--4.b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type,
		ROUND(SUM(total_drug_cost), 2) AS total_drug_cost
FROM drug
INNER JOIN prescription
USING (drug_name)
WHERE opioid_drug_flag <> 'N' OR antibiotic_drug_flag <> 'N'
GROUP BY drug_type
ORDER BY total_drug_cost DESC
--4.b ANSWER: Opioids($105,080,626.37) cost more than Antibiotics($38,435,121.26).





--5.a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
SELECT state, COUNT(cbsa) AS cbsa_count
FROM cbsa
INNER JOIN fips_county
USING(fipscounty)
WHERE state = 'TN'
GROUP BY state
--5.a ANSWER: CBSAs in Tennessee,	42

--5.b.Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsa, cbsaname, SUM(population) AS largest_combined_population
FROM cbsa
INNER JOIN population
USING (fipscounty)
GROUP BY cbsaname, cbsa
ORDER BY largest_combined_population DESC
--5.b ANSWER    largest combined population = 1830410,    from Nashville-Davidson--Murfreesboro--Franklin, TN.    cbsa = 34980
--		        smallest combined population = 116352,    from Morristown, TN.    						    	  cbsa = 34100

--5.c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population
SELECT county, SUM(population) AS largest_population
FROM fips_county
INNER JOIN population
USING (fipscounty)
FULL JOIN cbsa
USING (fipscounty)
WHERE cbsa IS NULL
GROUP BY county
ORDER BY largest_population DESC
--5.c ANSWER: "SEVIER"	95,523





--6.a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, SUM(total_claim_count) as total_claims
FROM  prescription
GROUP BY drug_name
HAVING SUM(total_claim_count) >= 3000
ORDER BY total_claims DESC
--6.a ANSWER is in the code

--6.b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, SUM(total_claim_count) as total_claims, opioid_drug_flag as opioid
FROM  prescription
INNER JOIN drug
USING(drug_name)
GROUP BY drug_name,opioid
HAVING SUM(total_claim_count) >= 3000 and opioid_drug_flag = 'Y'
ORDER BY total_claims DESC
--6.b ANSWER is in the code

--6.c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT nppes_provider_first_name AS first_name,
	nppes_provider_last_org_name AS last_name,
	drug_name,
	SUM(total_claim_count) as total_claims,
	opioid_drug_flag as opioid
FROM prescription
INNER JOIN drug
USING(drug_name)
INNER JOIN prescriber
USING(npi)
GROUP BY first_name, last_name, drug_name, opioid
HAVING SUM(total_claim_count) >= 3000 and opioid_drug_flag = 'Y'
ORDER BY total_claims DESC
--6.c ANWER   "DAVID"    "COFFEY"	 "OXYCODONE HCL"	            4588	   "Y"
--            "DAVID"    "COFFEY"	 "HYDROCODONE-ACETAMINOPHEN"	3414	   "Y"





--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

--a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT prescriber.npi,
	prescription.drug_name
FROM prescriber
CROSS JOIN prescription
LEFT JOIN drug
USING (drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY total_claim_count
--b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT prescriber.npi,
	prescription.drug_name,
	SUM(prescription.total_claim_count) AS number_of_claims
FROM prescriber
CROSS JOIN prescription
LEFT JOIN drug
USING (drug_name)
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, prescription.drug_name
ORDER BY SUM(prescription.total_claim_count)

--c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT prescriber.npi,
	prescription.drug_name,
	SUM(prescription.total_claim_count)
FROM prescriber
LEFT JOIN prescription
USING (npi)
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, prescription.drug_name






