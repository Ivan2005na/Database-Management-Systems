-- 1. Write a query that determines which additional services are provided by the mobile network operator TELE2.Explanation: I join the MobileNetworkOperator, OperatorAdditionalService, and AdditionalService tables, filtering by operatorName 'TELE2' to get the service names and their prices.
SELECT A.additionalServiceName, OAS.price
FROM MobileNetworkOperator M
JOIN OperatorAdditionalService OAS ON M.operatorID = OAS.operatorID
JOIN AdditionalService A ON OAS.additionalServiceID = A.additionalServiceID
WHERE M.operatorName = 'TELE2';

-- 2. Write a query that returns the additional services offered by all mobile network operators.Explanation: I join the MobileNetworkOperator, OperatorAdditionalService, and AdditionalService tables without filtering, to return the operator name, service name, and price for all available combinations.
SELECT M.operatorName, A.additionalServiceName, OAS.price
FROM MobileNetworkOperator M
JOIN OperatorAdditionalService OAS ON M.operatorID = OAS.operatorID
JOIN AdditionalService A ON OAS.additionalServiceID = A.additionalServiceID;

-- 3. Write a query that returns the number of countries belonging to each zone.Explanation: I join the Zone and Country tables, group by zone ID and name, and count the number of country IDs in each zone using the COUNT() function.
SELECT Z.zoneName, COUNT(C.countryID) AS NumberOfCountries
FROM Zone Z
JOIN Country C ON Z.zoneID = C.zoneID
GROUP BY Z.zoneID, Z.zoneName;

-- 4. Write a query that returns the name of the operator offering the most expensive calls to Mexico.Explanation: I use a Common Table Expression (CTE) to find the call rates to Mexico for each operator, then select the operator whose rate matches the MAX() rate to account for potential ties.
WITH OperatorCallPrices AS (
    SELECT M.operatorName, R.pricePerMinute
    FROM MobileNetworkOperator M
    JOIN Plan P ON M.operatorID = P.operatorID
    JOIN InternationalRate R ON P.planID = R.planID
    JOIN Country C ON R.countryID = C.countryID
    WHERE C.countryName = 'Mexico'
)
SELECT operatorName
FROM OperatorCallPrices
WHERE pricePerMinute = (SELECT MAX(pricePerMinute) FROM OperatorCallPrices);

-- 5. Write a query that finds the internet data plan that is not included in any mobile plan and has the lowest price per 1 MB.Explanation: I use a LEFT JOIN to find internet plans with no associated mobile plan (planID IS NULL), calculate the price per MB, order by this calculated value in ASC order, and limit the result to 1.
SELECT 
    M.operatorName, 
    I.internetDataPlanName, 
    (I.price / I.includedDataMB) AS pricePerMB
FROM InternetDataPlan I
JOIN MobileNetworkOperator M ON I.operatorID = M.operatorID
LEFT JOIN Plan P ON I.internetDataPlanID = P.internetDataPlanID
WHERE P.planID IS NULL
ORDER BY pricePerMB ASC
LIMIT 1;

-- 6. Write a query that returns the percentage distribution of subscribers among mobile network operators.Explanation: I use CTEs to calculate both the total number of subscribers and the count per operator, then I cross join them to calculate the percentage (subCount * 100.0 / totalCount).
WITH OperatorSubscriberCount AS (
    SELECT M.operatorName, COUNT(S.subscriberID) as subCount
    FROM MobileNetworkOperator M
    LEFT JOIN Plan P ON M.operatorID = P.operatorID
    LEFT JOIN Subscriber S ON P.planID = S.planID
    GROUP BY M.operatorID, M.operatorName
),
TotalSubscribers AS (
    SELECT COUNT(subscriberID) as totalCount FROM Subscriber
)
SELECT 
    O.operatorName, 
    (O.subCount * 100.0 / T.totalCount) AS SubscriberPercentage
FROM OperatorSubscriberCount O
CROSS JOIN TotalSubscribers T;

-- 7. Write a query that returns the three most popular mobile plans among subscribers.Explanation: I use the DENSE_RANK() window function to rank plans based on their subscriber count in descending order, then filter for ranks 1 to 3 in the main query, which automatically handles ties.
WITH PlanCounts AS (
    SELECT P.planName, COUNT(S.subscriberID) AS SubCount,
           DENSE_RANK() OVER (ORDER BY COUNT(S.subscriberID) DESC) as rnk
    FROM Plan P
    JOIN Subscriber S ON P.planID = S.planID
    GROUP BY P.planID, P.planName
)
SELECT planName, SubCount
FROM PlanCounts
WHERE rnk <= 3;

-- 8. Write a query that returns information about ten randomly selected subscribers.Explanation: I join all necessary tables (Subscriber, Person, City, Plan, MobileNetworkOperator), use CASE statements to check for extra data/services, and use ORDER BY RANDOM() with a LIMIT of 10 to get a random sample.
SELECT 
    P.firstName || ' ' || P.lastName AS fullName,
    C.cityName,
    S.phoneNumber,
    S.contractStartDate,
    S.contractEndDate,
    M.operatorName,
    PL.planName,
    CASE WHEN S.additionalInternetDataPlanID IS NOT NULL THEN 'Yes' ELSE 'No' END AS hasExtraData,
    CASE WHEN EXISTS (SELECT 1 FROM SubscriberAdditionalService SAS WHERE SAS.subscriberID = S.subscriberID) THEN 'Yes' ELSE 'No' END AS hasExtraServices
FROM Subscriber S
JOIN Person P ON S.personID = P.personID
JOIN City C ON P.cityID = C.cityID
JOIN Plan PL ON S.planID = PL.planID
JOIN MobileNetworkOperator M ON PL.operatorID = M.operatorID
ORDER BY RANDOM()
LIMIT 10;

-- 9. Write a query that returns the top five subscribers by the number of calls made within Lithuania during October 2013.Explanation: I join the CallRecord and Country tables, filter for Lithuania and October 2013 dates, use DENSE_RANK() to rank by call count, and select the top 5.
WITH CallCounts AS (
    SELECT S.subscriberID, COUNT(CA.callID) as CallCount,
           DENSE_RANK() OVER (ORDER BY COUNT(CA.callID) DESC) as rnk
    FROM Subscriber S
    JOIN CallRecord CA ON S.subscriberID = CA.callerID
    JOIN Country CO ON CA.destinationCountryID = CO.countryID
    WHERE CO.countryName = 'Lithuania' 
      AND CA.callDate BETWEEN '2013-10-01' AND '2013-10-31'
    GROUP BY S.subscriberID
)
SELECT S.phoneNumber, C.CallCount
FROM CallCounts C
JOIN Subscriber S ON C.subscriberID = S.subscriberID
WHERE C.rnk <= 5;

-- 10. Write a query that determines the most popular foreign country based on the number of calls made to that country.Explanation: I create a CTE to count calls per country excluding Lithuania, then select the country matching the MAX() call count to ensure all ties are included.
WITH CountryCallCounts AS (
    SELECT CO.countryName, COUNT(CA.callID) AS CallCount
    FROM CallRecord CA
    JOIN Country CO ON CA.destinationCountryID = CO.countryID
    WHERE CO.countryName != 'Lithuania'
    GROUP BY CO.countryID, CO.countryName
)
SELECT countryName
FROM CountryCallCounts
WHERE CallCount = (SELECT MAX(CallCount) FROM CountryCallCounts);
