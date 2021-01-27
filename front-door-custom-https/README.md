# Front Door with custom domain and HTTPS

This example is an extended version of the [Front Door with custom domain example on the official repo](https://github.com/johndowns/bicep/blob/main/docs/examples/101/front-door-custom-domain/main.bicep). This version includes the configuration of HTTPS on the custom domain.

This example cannot be submitted to the Bicep examples repo currently because it uses a type not defined correctly, [as tracked on this Bicep issue](https://github.com/Azure/bicep/issues/784). These resource types deploy successfully but trigger a warning by the Bicep CLI.
