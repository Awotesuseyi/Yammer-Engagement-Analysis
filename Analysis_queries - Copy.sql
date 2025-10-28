-- =====================================================
-- YAMMER ENGAGEMENT ANALYSIS - SQL QUERIES
-- Author: AWOTESU SEYI ADURAGBEMI
-- Date: October 2025
-- =====================================================

-- =====================================================
-- SECTION 1: DATA QUALITY & INSPECTION
-- =====================================================

USE Yammer_data;

-- Query 1: Check data completeness

SELECT 
  'yammer_users' AS table_name,
  COUNT(*) AS total_records,
  COUNT(user_id) AS non_null_user_id,
  COUNT(created_at) AS non_null_created_at,
  COUNT(company_id) AS non_null_company_id,
  COUNT(state) AS non_null_state
FROM yammer_users

UNION ALL

SELECT 
  'yammer_events' AS table_name,
  COUNT(*) AS total_records,
  COUNT(user_id) AS non_null_user_id,
  COUNT(occurred_at) AS non_null_occurred_at,
  COUNT(event_type) AS non_null_event_type,
  COUNT(device) AS non_null_device
FROM yammer_events

UNION ALL

SELECT 
  'yammer_emails' AS table_name,
  COUNT(*) AS total_records,
  COUNT(user_id) AS non_null_user_id,
  COUNT(occurred_at) AS non_null_occurred_at,
  COUNT(action) AS non_null_action,
  NULL AS non_null_extra
FROM yammer_emails;


-- Query 2: Date range verification

SELECT 
  'yammer_events' AS table_name,
  MIN(occurred_at) AS earliest_date,
  MAX(occurred_at) AS latest_date,
  DATEDIFF(day, MIN(occurred_at), MAX(occurred_at)) AS days_covered
FROM yammer_events

UNION ALL

SELECT 
  'yammer_emails' AS table_name,
  MIN(occurred_at) AS earliest_date,
  MAX(occurred_at) AS latest_date,
  DATEDIFF(day, MIN(occurred_at), MAX(occurred_at)) AS days_covered
FROM yammer_emails;


-- =====================================================
-- SECTION 2: BASELINE ANALYSIS
-- =====================================================

-- Query 3: Weekly Active Users Baseline
-- Purpose: Identify when engagement dropped

WITH User_engagement AS
(
SELECT DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)) week_dates,
		COUNT( DISTINCT user_id) AS weekly_active_users
FROM yammer_events
WHERE event_type = 'engagement'
GROUP BY DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at))
)
SELECT week_dates,
		weekly_active_users
FROM User_engagement
ORDER BY week_dates


-- From the chart plotted engagement dropped exactly in the week of August 4th

-- There was a peak from July 20th to July 28th before the crash from July 28th to August 4th
-- indicating that something went wrong between July 28th to August 4th

-- Total Engagement dropped from 1,443 July 28th to 1,266 August 4th 12.2% decrease

-- Engagement has stayed low not recovered indicating that what ever is broken that 
-- has caused user churn and it's driving people away permanently.


-- =====================================================
-- SECTION 3: HYPOTHESIS TESTING
-- =====================================================

-- Query 4: Search Functionality Analysis
-- Purpose: Test if search features broke

WITH Search_functionality AS
(
SELECT DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)) week_dates,
	COUNT( DISTINCT CASE WHEN event_name = 'search_run' THEN user_id ELSE NULL END) AS search_run,
	COUNT( DISTINCT CASE WHEN event_name LIKE '%search_click_result%' THEN user_id ELSE NULL END) AS search_click_results,
	COUNT( DISTINCT CASE WHEN event_name = 'search_autocomplete' THEN user_id ELSE NULL END) AS search_autocomplete,
	COUNT( DISTINCT CASE WHEN event_type = 'engagement' THEN user_id ELSE NULL END) AS total_engagement
FROM yammer_events
GROUP BY DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at))
)
SELECT week_dates,
		search_run,
		search_click_results,
		search_autocomplete,
		total_engagement,
		ROUND((search_run * 100)/total_engagement,2) AS search_penetration_perc,
		ROUND((search_click_results * 100)/total_engagement,2) AS search_click_results_perc
FROM Search_functionality
ORDER BY week_dates

--	 Search penetration percentage dropped from 14% July 28th to 13% August 4th 1% decrease

---- Search autocomplete dropped from 533 July 28th to 485 August 4th 9% decrease, this means 
---- users can still type searches

---- Search click result dropped from 104 July 28th to 75 August 4th 27.8% decrease,this means users stopped
---- clicking results

---- Search run dropped from 208 July 28th to 177 August 4th 14.9% decrease, this means
---- users can still run searches. 

---- Hypothesis I: It is most likely that Search results page is showing irrelevant/broken results, 
----or the click tracking broke, or results aren't loading properly.




-- Query 5: Email Notification Analysis
-- Purpose: Check email clickthrough rates

WITH email_actions AS
(
SELECT	DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)) week_dates,
		COUNT(CASE WHEN ye.action = 'email_open' THEN ye.user_id END) emails_open,
		COUNT(CASE WHEN ye.action = 'sent_reengagement_email' THEN ye.user_id END) sent_reengagement_email,
		COUNT(CASE WHEN ye.action = 'email_clickthrough' THEN ye.user_id END) email_clickthrough,
		COUNT(CASE WHEN ye.action = 'sent_weekly_digest' THEN ye.user_id END) sent_weekly_digest
FROM yammer_emails ye
GROUP BY DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at))
)
SELECT week_dates,
		email_clickthrough,
		emails_open,
		sent_reengagement_email,
		sent_weekly_digest,
		CONCAT((emails_open * 100)/NULLIF(sent_weekly_digest,0),'%') AS open_rates_perc,
		CONCAT((email_clickthrough * 100)/NULLIF(emails_open,0),'%') AS clickthrough_rates_perc
FROM email_actions
ORDER BY week_dates

---- Sent weekly digest  increased by 2.3% from 3,706 July 28th to 3,793 August 4th, this means that 
---- emails are still being sent to drive users back to the platform

---- Sent reengaement email decreased by 10.4% from 230 July 28th to 206 August 4th

---- Email open  decreased by 3.6% from 1,386 July 28th to 1,336 August 4th, this means that emails are 
---- still being opened

---- Email click_through decreased by 31.7% from 633 in July 28th to 432 August 4th, this means that users 
---- stopped clicking links in emails 

---- Email open rate dcreased by 2% from 37% in July 28th to 35% August 4th 

---- Click through rate decreased by 13% fron 45% in July 28th to 32% August 4th

---- Hypothesis II: The Problem Isn't Search OR Email It's LINKS,
---- Something broke in the linking/routing system between July 28 → Aug 4.



-- Query 6: Device-Specific Analysis
-- Purpose: Isolate mobile vs desktop impact

USE Yammer_data;
WITH Devices AS
(
SELECT DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)) week_dates,
	COUNT( DISTINCT CASE WHEN device IN ('nokia lumia 635','htc one','iphone 4s','nexus 10',
		'nexus 5','samsung galaxy s4','iphone 5s','kindle fire','samsung galaxy note','nexus 7',
		'ipad mini','ipad air','amazon fire phone','iphone 5','amazon fire phone','nokia lumia 635',
		'nokia lumia 635','iphone 4s','samsumg galaxy tablet')  THEN user_id ELSE NULL END) AS Mobile_phones,
	COUNT( DISTINCT CASE WHEN device IN ('dell inspiron notebook','acer aspire notebook','lenovo thinkpad',
			'mac mini','hp pavilion desktop','windows surface','dell inspiron desktop','macbook air','macbook pro',
		'acer aspire desktop','asus chromebook') THEN user_id ELSE NULL END) AS Desktop,
	COUNT( DISTINCT CASE WHEN event_type = 'engagement' THEN user_id ELSE NULL END) AS total_engagement
FROM yammer_events
GROUP BY DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at))
)
SELECT week_dates,
		Mobile_phones,
		Desktop,
		total_engagement
FROM Devices
ORDER BY week_dates

-- Mobile Phones used for engagement dropped by 19.3% from 732 in July 28th to 590 in August 4th
-- which 5.6x worse than desktop

-- Desktops used by users for engagement dropped by 4.5% from 965 in July 28th to 921 in August 4th which has 
-- Minimal impact meaning that desktop users are relatively unaffected, they're still engaging normally

-- It is Most Likely that A mobile app update deployed between July 28-Aug 4 that broke deep linking.
-- When mobile users Click email links, App doesn't open the right page they Click search results and navigation
-- fails or times out or try to interact with content and Links don't work So they abandon the app and don't come back.
-- While Desktop users unaffected because they're using web interface where links still work.


-- Query 7: Mobile Click Validation
-- Purpose: Confirm mobile users stopped clicking

WITH User_devices AS
(
SELECT DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)) week_dates,
		yevents.user_id,
	CASE WHEN yevents.device IN ('nokia lumia 635','htc one','iphone 4s','nexus 10',
		'nexus 5','samsung galaxy s4','iphone 5s','kindle fire','samsung galaxy note','nexus 7',
		'ipad mini','ipad air','amazon fire phone','iphone 5','amazon fire phone','nokia lumia 635',
		'nokia lumia 635','iphone 4s','samsumg galaxy tablet')  THEN 'Mobile_phones'
       WHEN yevents.device IN ('dell inspiron notebook','acer aspire notebook','lenovo thinkpad',
			'mac mini','hp pavilion desktop','windows surface','dell inspiron desktop','macbook air','macbook pro',
		'acer aspire desktop','asus chromebook') THEN 'Desktop'
	ELSE NULL END AS Devices
FROM yammer_events yevents
WHERE event_type = 'engagement'
GROUP BY DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)),yevents.device,yevents.user_id
)
SELECT DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)) week_dates,
		ud.Devices,
		COUNT(*) AS search_click_results
FROM yammer_events ye
JOIN User_devices ud
	ON ye.user_id = ud.user_id
WHERE ud.Devices = 'Mobile_phones'
AND ye.event_name LIKE '%search_click_result%' 
GROUP BY DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)),ud.Devices
ORDER BY DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at))


--  From users with mobile phones search click result crashed by 26.1% from 2,430 in July 28th to 1,794 in August 4th



-- =====================================================
-- SECTION 4: ROOT CAUSE VALIDATION
-- =====================================================

-- Query 8: Device Model Breakdown
-- Purpose: Prove all mobile devices affected

WITH Device_category AS
(
SELECT	device,
		occurred_at,
		user_id,
		CASE WHEN device IN ('nokia lumia 635','htc one','iphone 4s','nexus 10',
		'nexus 5','samsung galaxy s4','iphone 5s','kindle fire','samsung galaxy note','nexus 7',
		'ipad mini','ipad air','amazon fire phone','iphone 5','amazon fire phone','nokia lumia 635',
		'nokia lumia 635','iphone 4s','samsumg galaxy tablet')  THEN 'Mobile_phones'
       WHEN device IN ('dell inspiron notebook','acer aspire notebook','lenovo thinkpad',
			'mac mini','hp pavilion desktop','windows surface','dell inspiron desktop','macbook air','macbook pro',
		'acer aspire desktop','asus chromebook') THEN 'Desktop'
	ELSE NULL END AS Devices_types
FROM yammer_events 
WHERE event_type = 'engagement'
),
July_Users AS
(
SELECT	DISTINCT device,
		COUNT(DISTINCT user_id) July_user,
		Devices_types
FROM Device_category 
WHERE DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)) = '2014-07-28'
GROUP BY device,Devices_types
),
Aug_Users AS
(
SELECT  DISTINCT device,
		COUNT(DISTINCT user_id) Aug_user,
		Devices_types
FROM Device_category 
WHERE DATEADD(DAY,1,DATETRUNC(WEEK, occurred_at)) = '2014-08-04'
GROUP BY device,Devices_types
)
SELECT DISTINCT a.device,
		a.Devices_types,
		j.July_user,
		a.Aug_user,
		CONCAT((a.Aug_user - j.July_user) * 100/j.July_user,'%') AS Engagement_change
FROM July_Users j
JOIN Aug_Users a
	ON a.device = J.device
WHERE a.Devices_types = 'Mobile_phones'
ORDER BY a.device
