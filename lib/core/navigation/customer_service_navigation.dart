const customerServicePath = '/#/DioritesGaoling';

String customerServiceUrl(Uri webBaseUrl) =>
    webBaseUrl.resolve(customerServicePath).toString();
