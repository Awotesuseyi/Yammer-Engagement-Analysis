# Project Background
Microsoft’s Viva Engage (formerly Yammer) was originally founded in 2008 by David O. Sacks and Adam Pisoni and acquired by Microsoft in 2012 for $1.2 billion. Yammer was integrated into Microsoft 365 to enhance internal communication and collaboration across organizations. In 2023, it was rebranded as Viva Engage, expanding its focus to employee engagement, community building, and knowledge sharing. Operating within the enterprise collaboration and employee experience industry, the platform follows a SaaS business model as part of the Microsoft 365 suite. Today, Viva Engage serves over 85% of Fortune 500 companies, reflecting its strong impact on organizational communication and connectedness.


On Tuesday, September 2, 2014, the Product team identified a sharp decline in user engagement on Yammer's platform. Weekly active users dropped from 1,443 in the week of July 28th to 1,266 by August 4th, a 12.2% decrease in just one week, with no signs of recovery in subsequent weeks. This sustained engagement drop posed a critical threat to Yammer's core value proposition as a social networking platform for workplace collaboration. As a data analyst, I am tasked with investigating the root cause of this decline and determining whether it stemmed from technical issues, product changes, seasonal factors, or user behavior shifts.


**Insights and recommendations are provided on the following key areas:**

**Category 1**: Engagement Health & Retention <br>
**Category 2**:  Mobile User Experience <br>
**Category 3**:  Product Feature Performance <br>
**Category 4**:  Technical Infrastructure Issues <br>


Targeted SQL queries regarding various business questions can be found here.[Analysis_queries.sql](https://github.com/user-attachments/files/23197618/Analysis_queries.sql) .

Power BI dashboard used to report and explore engagement trends can be found here (https://app.powerbi.com/groups/me/reports/2b6069d2-6ee1-4354-97e6-ea246b4aa2ff/22a248408dbdd5e8702e?experience=power-bi).

# Data Structure & Initial Checks

Microsoft’s Viva Engage main database structure, as seen below, consists of three tables: Users, Events, and Email, with a total row count of 19,066 records. A description of each table is as follows:

**Table 1**: Users
This table includes one row per user, with descriptive information about that user's account.

          - user_id: A unique ID per user. Can be joined to user_id in either of the other tables.
          - created_at: The time the user was created (first signed up)
          - state: The state of the user (active or pending)
          - activated_at: The time the user was activated, if they are active
          - company_id: The ID of the user's company
          - language: The chosen language of the user
          - language: The chosen language of the user

**Table 2**: Events
This table includes one row per event, where an event is an action that a user has taken on Yammer. These events include login events, messaging events, search events, events logged as users progress through a signup funnel, and events around received emails.

            
        - user_id: The ID of the user logging the event. Can be joined to user_id in either of the other tables.
        - occurred_at:	The time the event occurred.
        - event_type:	The general event type. There are two values in this 
                  dataset: "signup_flow," which refers to anything occurring during the process of a user's authentication, 
                  and "engagement," which refers to general product usage after the user has signed up for the first time.
        - event_name:	The specific action the user took. Possible values include: 
                    create_user: User is added to Yammer's database during signup process
                    enter_email: The user begins the signup process by entering her email address 
                    enter_info: The user enters her name and personal information during signup process 
                    complete_signup: User completes the entire signup/authentication process 
                    home_page: User loads the home page like_message: The user likes another user's 
                    message login: The user logs into Yammer search_autocomplete: The user selects a search result from the autocomplete list 
                    search_run: The user runs a search query and is taken to the search results page 
                    search_click_result_X: The user clicks search result X on the results page, where X is a number from 1 through 
                    send_message: The user posts a message view_inbox: The user views messages in her inbox
        - location:	The country from which the event was logged (collected through IP address).
        - device:	The type of device used to log the event.


**Table 3**: Email 
This table contains events specific to the sending of emails. It is similar in structure to the events table above.

        - user_id:	The ID of the user to whom the event relates. Can be joined to user_id in either of the other tables.
        - occurred_at:	The time the event occurred.
        - action:	The name of the event that occurred. 
                  "sent_weekly_digest" means that the user was delivered a digest email showing relevant conversations from the previous day.
                  "email_open" means that the user opened the email.
                  "email_clickthrough" means that the user clicked a link in the email.


                  

<img width="449" height="350" alt="Image" src="https://github.com/user-attachments/assets/7cb3bc4d-efec-4f17-99e6-df15f2c69573" />




# **EXECUTIVE SUMMARY**

### **Overview of Findings**

Between July 28 and August 4, 2014, Yammer experienced a 12.3% drop in weekly active users that has not recovered, representing a sustained loss of approximately 250 engaged users per week. Investigation reveals this decline is not a product-wide failure but a mobile-specific crisis: mobile engagement crashed 19.3%, while desktop usage remained stable at -4.5%. The root cause is a broken click/deep-linking system in the mobile app that prevents users from navigating through search results and email links, effectively crippling the mobile user experience and driving permanent user abandonment.

<img width="449" height="350" alt="image" src="https://github.com/user-attachments/assets/c4251364-becb-4b5c-aed1-1bbc8be20aab" />



# **Insights Deep Dive**

### Category 1: Engagement Health & Retention
- Weekly active users dropped from 1,443 (July 28) to 1,266 (Aug 4), representing a sustained 17.2% decline
- No recovery observed through August 25, indicating permanent user churn rather than temporary dip
- Peak engagement occurred week of July 28, making this the "last normal week" baseline
- Approximately 249 users lost per week sustained through month-end


<img width="500" height="450" alt="image" src="https://github.com/user-attachments/assets/1809a822-7044-44c4-a4e6-23827678560f" />


### Category 2: Mobile User Experience  
- Mobile engagement crashed 19.4% (732 → 590 users) vs desktop's 4.6% drop (965 → 921 users)
- Mobile users experienced 4.2x worse impact than desktop users
- All mobile device models affected equally (-15% to -25% range), proving platform-wide failure
- Issue not device-specific: iPhone, Android, and tablet users all impacted similarly

<img width="449" height="350" alt="image" src="https://github.com/user-attachments/assets/bcfb14e2-f8cd-404e-a538-6b1608d95a2e" />
<img width="449" height="350" alt="image" src="https://github.com/user-attachments/assets/3f783549-1942-47a4-97fd-b20c6b2c236a" />


### Category 3: Product Feature Performance
- Search result clicks collapsed 46.7% on mobile vs 15% on desktop
- Email clickthrough rate dropped 33.4% (17.1% → 11.4%)  
- Email open rates remained stable (-3.7%), confirming emails delivered but links broken
- Core features (messaging, home page views) continued functioning normally

<img width="449" height="350" alt="image" src="https://github.com/user-attachments/assets/19dda624-7c4a-449d-9601-abda4315521a" />

<img width="550" height="450" alt="image" src="https://github.com/user-attachments/assets/9f9debf3-a965-41b4-8d89-7fa91e04acc1" />

### Category 4: Technical Infrastructure Issues
- Click behavior broke across ALL search result positions (1-10), not just lower-ranked results
- Email notification links failed to route users to content
- Search functionality operational (queries running) but result clicks failed
- Evidence points to URL routing/deep-linking system failure deployed July 28-Aug 4

<img width="458" height="362" alt="page3_forensics" src="https://github.com/user-attachments/assets/980a1f06-894b-4804-86f9-018968fe750b" />


## RECOMMENDATIONS

Based on the investigation, we recommend the Product and Engineering teams:

**Immediate Actions (Priority 1):**
- Rollback mobile application to pre-July 28 version to restore navigation functionality
- Deploy emergency fix within 24-48 hours to stop ongoing user churn (197 users/week)

**Root Cause Analysis (Priority 2):**  
- Audit all code changes deployed between July 28-August 4, 2014
- Review mobile deep-linking, URL routing, and click handler implementations
- Test email-to-app and search-to-content navigation flows across all device types

**Monitoring & Prevention (Priority 3):**
- Implement real-time monitoring for click-through rates by device type
- Create alerts for >10% week-over-week drops in mobile click behavior
- Establish staged rollout process for mobile releases with rollback criteria

**User Recovery (Priority 4):**
- Plan re-engagement campaign for churned mobile users post-fix
- Consider push notifications announcing "navigation improvements" once resolved

## ASSUMPTIONS AND CAVEATS

Throughout the analysis, the following assumptions were made:

**Assumption 1**: Device classification based on device name strings is accurate. Some device names may be misclassified if they don't match the predefined lists.

**Assumption 2**: Week-over-week comparison uses Monday as week start date. SQL uses DATE_TRUNC(WEEK) which may vary by database configuration.

**Assumption 3**: "Engagement" is defined as any server call event (event_type = 'engagement'). This excludes signup_flow events which represent pre-authentication activity.

**Assumption 4**: Data for August 4th, 2014 represents a complete week. Partial week data could skew final metrics.

**Assumption 5**: Email metrics track user actions, not email delivery. ISP filtering or spam folder placement not captured in this analysis.


