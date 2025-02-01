import Keycloak from 'keycloak-js';

const keycloakClient = new Keycloak({
    url: 'http://localhost:8080/',
    realm: 'myrealm',
    clientId: 'frontend-client',
});

export default keycloakClient;
