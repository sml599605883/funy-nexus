const customerServicePath = '/#/DioritesGaoling';
const privacyPolicyPath = '/#/BullyInfesters';

String customerServiceUrl(Uri webBaseUrl) =>
    webBaseUrl.resolve(customerServicePath).toString();

String privacyPolicyUrl(Uri webBaseUrl) =>
    webBaseUrl.resolve(privacyPolicyPath).toString();
