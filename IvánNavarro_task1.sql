-- 1. Count the number of records in the City table.Explanation: I use the COUNT(*) aggregation function to count all rows that exist within the City table, without filtering anything.
SELECT COUNT(*) AS NumberOfRecords 
FROM City;

-- 2, 3, 4. Return the plans that include an internet data plan, extending the result with internet data plan details and the mobile network operator name.Explanation: I use an INNER JOIN between Plan and InternetDataPlan to get the data plan details, and another JOIN with MobileNetworkOperator to get the operator's name, filtering where internetDataPlanID is not null.
SELECT 
    P.planName, 
    P.price AS planPrice, 
    I.internetDataPlanName, 
    I.includedDataMB, 
    I.price AS internetDataPlanPrice, 
    M.operatorName
FROM Plan P
JOIN InternetDataPlan I ON P.internetDataPlanID = I.internetDataPlanID
JOIN MobileNetworkOperator M ON P.operatorID = M.operatorID;

-- 5. Return all mobile network operators and the plans they offer that include at least 100 free minutes for calls within the Lithuanian network.Explanation: I join the MobileNetworkOperator and Plan tables, using a WHERE clause to filter for plans that have includedMinLT greater than or equal to 100.
SELECT 
    M.operatorName, 
    P.planName, 
    P.price
FROM MobileNetworkOperator M
JOIN Plan P ON M.operatorID = P.operatorID
WHERE P.includedMinLT >= 100;

-- 6. Return a summary showing the number of users in each city.Explanation: I join the City and Person tables, group the results by city, and use the COUNT() function on the personID to get the total number of users per city.
SELECT 
    C.cityName, 
    COUNT(P.personID) AS NumberOfUsers
FROM City C
JOIN Person P ON C.cityID = P.cityID
GROUP BY C.cityID, C.cityName;

-- 7. Return the cities with no users.Explanation: I use a LEFT JOIN from City to Person and filter with a WHERE clause looking for NULL personIDs, which indicates cities that have no associated users.
SELECT 
    C.cityName
FROM City C
LEFT JOIN Person P ON C.cityID = P.cityID
WHERE P.personID IS NULL;

-- 8. Calculate the average number of users per city excluding cities with no users.Explanation: I use a subquery to count users per city grouped by cityID from the Person table, which naturally excludes empty cities, and then calculate the AVG() of those counts.
SELECT AVG(UserCount) AS AvgUsersExcludingEmptyCities
FROM (
    SELECT COUNT(personID) AS UserCount
    FROM Person
    GROUP BY cityID
) AS CityUserCounts;

-- 8. Calculate the average number of users per city including cities with no users.Explanation: I use a subquery with a LEFT JOIN from City to Person so empty cities return a count of 0, and then I apply the AVG() function to those counts.
SELECT AVG(UserCount) AS AvgUsersIncludingEmptyCities
FROM (
    SELECT COUNT(P.personID) AS UserCount
    FROM City C
    LEFT JOIN Person P ON C.cityID = P.cityID
    GROUP BY C.cityID
) AS CityUserCountsWithEmpty;

-- 9. Return the name of the operator offering the largest number of plans, returning all if there's a tie.Explanation: I create a Common Table Expression (CTE) to count plans per operator, then select operators whose count matches the MAX() count from that CTE to handle potential ties.
WITH OperatorPlanCounts AS (
    SELECT operatorID, COUNT(planID) AS PlanCount
    FROM Plan
    GROUP BY operatorID
)
SELECT M.operatorName
FROM MobileNetworkOperator M
JOIN OperatorPlanCounts O ON M.operatorID = O.operatorID
WHERE O.PlanCount = (SELECT MAX(PlanCount) FROM OperatorPlanCounts);

-- 10, 11. Return a list of people who subscribed to any plan between January 3, 2025 and January 10, 2025, inclusive.Explanation: I join the Person, Subscriber, and Plan tables, and use the BETWEEN operator to filter the contractStartDate within the specified date range.
SELECT 
    P.firstName, 
    P.lastName, 
    PL.planName, 
    S.contractStartDate
FROM Person P
JOIN Subscriber S ON P.personID = S.personID
JOIN Plan PL ON S.planID = PL.planID
WHERE S.contractStartDate BETWEEN '2025-01-03' AND '2025-01-10';

-- 12, 13, 14. Calculate the average price of the plans offered by each operator, sorted in descending order.Explanation: I join the MobileNetworkOperator and Plan tables, group by operator, calculate the AVG() of the plan price, and order the final result in DESC (descending) order.
SELECT 
    M.operatorName, 
    AVG(P.price) AS averagePlanPrice
FROM MobileNetworkOperator M
JOIN Plan P ON M.operatorID = P.operatorID
GROUP BY M.operatorID, M.operatorName
ORDER BY averagePlanPrice DESC;

-- 15, 16. Determine how many additional services are provided by each operator.Explanation: I use a LEFT JOIN from MobileNetworkOperator to OperatorAdditionalService to ensure all operators are included even if they have 0 services, group by operator, and count the additional service IDs.
SELECT 
    M.operatorName, 
    COUNT(OAS.additionalServiceID) AS NumberOfAdditionalServices
FROM MobileNetworkOperator M
LEFT JOIN OperatorAdditionalService OAS ON M.operatorID = OAS.operatorID
GROUP BY M.operatorID, M.operatorName;
