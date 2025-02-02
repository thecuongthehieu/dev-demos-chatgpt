import Keycloak from 'keycloak-js';

const keycloakClient = new Keycloak({
    url: 'http://localhost:8080/',
    realm: 'myrealm',
    clientId: 'frontend-client',
});

// Store the initialization promise to ensure it's only called once
keycloakClient.initPromise = keycloakClient.init({ onLoad: 'check-sso' });

export default keycloakClient;
