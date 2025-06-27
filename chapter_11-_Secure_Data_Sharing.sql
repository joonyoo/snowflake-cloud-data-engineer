

/*------------------------------
Chapter 11:  Secure Data Sharing
 ------------------------------*/

// Using the sequence function with a generator table function to create a resultset of incremental numbers.
select seq4()
from table(generator(rowcount => 50));


//describe the script below
//count * from table

select seq4()
from table(generator(rowcount => 1000000));

//


create or replace function FAKE_EN(provider varchar,parameters variant)
returns variant
language python
volatile
runtime_version = '3.10'
packages = ('faker','simplejson')
handler = 'main'
as
$$
import simplejson as json
from faker import Faker
def main(provider,parameters):
  if type(parameters).__name__=='sqlNullWrapper':
    parameters = {}
  fake = Faker(locale='en_US')
  return json.loads(json.dumps(fake.format(formatter=provider,**parameters), default=str))
$$;



select FAKE_EN('name',null)::varchar as NAME
 from table(generator(rowcount => 50));



select 
     FAKE_EN('date_of_birth',{'minimum_age':16, 'maximum_age':60})::varchar as first_name
 from table(generator(rowcount => 50));





create or replace  table user_profile as
 select
     FAKE_EN('profile',null)::variant as profile
    ,seq4() as profile_id
    ,profile:address::string as address
    ,profile:birthdate::string as birthdate
    ,profile:blood_group::string as blood_group
    ,profile:company::string as company
    ,profile:current_location::array as current_location
    ,profile:job::string as job
    ,profile:mail::string as mail
    ,profile:name::string as name
    ,profile:residence::string as residence
    ,profile:sex::string as sex
    ,profile:ssn::string as ssn
    ,profile:username::string as username
    ,profile:website::array as website
 from table(generator(rowcount => 100000));




--Creating a another snowflake account to consume the SHARE

use role orgadmin;

create account consumer_example_account
  admin_name = admin_user
  admin_password = '************'  --temporary password
  email = 'myemail@myorg.org'
  edition = enterprise;




--creating an email masking policy

CREATE MASKING POLICY email_mask as (val string) returns string ->
CASE
  WHEN current_role() IN ('ACCOUNTADMIN', 'GOVERNANCE') THEN val  -- donotreply@fakemail.com
  WHEN current_role() IN ('SYSADMIN') THEN regexp_replace(val,'.+\@','*****@') -- leave email domain unmasked  e.g. *****@example.com
  ELSE '********'  
END;





select SSN
from user_profile;



select SSN
    ,REGEXP_REPLACE(SSN, '[^0-9]', '')  as ssn_digits  --extract only digits
    ,HASH( HASH(current_account())  + ssn_digits )  as seed  --create a numeric seed from the account name
    ,HASH('lets generate a salt!') + HASH(ssn_digits)  as salt --random number for salt
    ,SHA2(ssn_digits + seed + salt) 
from user_profile;




CREATE MASKING POLICY ssn_mask as (val number) returns number ->
CASE
  WHEN current_role() IN ('ACCOUNTADMIN', 'GOVERNANCE') THEN val
  ELSE SHA2( REGEXP_REPLACE(val, '[^0-9]', '') --ssn_digits 
   + HASH( HASH(current_account())  + REGEXP_REPLACE(val, '[^0-9]', '') )  --seed
   + HASH(SHA2(REGEXP_REPLACE(val, '[^0-9]', '') )) --salt
   ) 
END;




alter table user_profile alter column ssn SET MASKING POLICY ssn_mask;
alter table user_profile alter column mail SET MASKING POLICY email_mask;



-- Test the mask
use role sysadmin;

select SSN, MAIL
from user_profile;

