set -e

APIKEY="KB"
APISECRET="KB"
BASEURL="http://127.0.0.1:18080"
CURRENCY="USD"

# CREATE Account
ACCOUNT_URI=`curl -si \
    -u admin:password \
    -H "X-Killbill-ApiKey: $APIKEY" \
    -H "X-Killbill-ApiSecret: $APISECRET" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "X-Killbill-CreatedBy: demo" \
    -H "X-Killbill-Reason: demo" \
    -H "X-Killbill-Comment: demo" \
    -d "{ \
          \"name\": \"Felix Gonschorek\", \
          \"email\": \"felix@mailinator.com\", \
          \"currency\": \"${CURRENCY}\", \
          \"timeZone\": \"Europe/Berlin\", \
          \"locale\": \"de_DE\" \
        }" \
    "${BASEURL}/1.0/kb/accounts" | grep -oP 'Location: \K.*' | tr -d '\r'`

ACCOUNT=`basename "$ACCOUNT_URI"`
echo "Created Account UUID: $ACCOUNT"

# CREATE Payment method
PAYMENT_URI=`curl -si \
    -u admin:password \
    -H "X-Killbill-ApiKey: $APIKEY" \
    -H "X-Killbill-ApiSecret: $APISECRET" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -H "X-Killbill-CreatedBy: demo" \
    -H "X-Killbill-Reason: demo" \
    -H "X-Killbill-Comment: demo" \
    -d "{ \
          \"accountId\": \"${ACCOUNT}\", \
          \"pluginName\": \"__EXTERNAL_PAYMENT__\", \
          \"isDefault\": \"true\" \
        }" \
    "${BASEURL}/1.0/kb/accounts/${ACCOUNT}/paymentMethods" | grep -oP 'Location: \K.*' | tr -d '\r'`
PAYMENT_TYPE=`basename "$PAYMENT_URI"`
echo "Created Payment UUID: $PAYMENT_TYPE"

# CREATE Migrated Subscription with billing date in the future
EXTERNAL_KEY=`uuid`
SUBSCRIPTION_URI=`curl -si \
    -u admin:password \
    -H "X-Killbill-ApiKey: $APIKEY" \
    -H "X-Killbill-ApiSecret: $APISECRET" \
    -H "Content-Type: application/json" \
    -H "X-Killbill-CreatedBy: demo" \
    -d "{ \
            \"accountId\": \"$ACCOUNT\", \
            \"externalKey\": \"${EXTERNAL_KEY}\", \
            \"planName\": \"standard-yearly\", \
            \"phaseType\": \"EVERGREEN\", \
            \"billCycleDayLocal\": 1 \
        }" \
    "${BASEURL}/1.0/kb/subscriptions?entitlementDate=2010-01-01&billingDate=2022-06-01&migrated=true" | grep -oP 'Location: \K.*' | tr -d '\r'`
    
SUBSCRIPTION=`basename "$SUBSCRIPTION_URI"`
echo "Subscription UUID:    $SUBSCRIPTION"

# CHANGE PLAN Subscription, this call crashes when billCycleDayLocal is set for subscription
EXTERNAL_KEY=`uuid`
curl -si \
    -X PUT \
    -u admin:password \
    -H "X-Killbill-ApiKey: $APIKEY" \
    -H "X-Killbill-ApiSecret: $APISECRET" \
    -H "Content-Type: application/json" \
    -H "X-Killbill-CreatedBy: demo" \
    -d "{ \
            \"planName\": \"standard-monthly\" \
        }" \
    "$SUBSCRIPTION_URI?callCompletion=true&callTimeoutSec=10"
