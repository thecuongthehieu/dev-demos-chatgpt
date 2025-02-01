import React, { useEffect, useState } from 'react';
import keycloakClient from './keycloak';
import axios from 'axios';

function App() {
    const [keycloak, setKeycloak] = useState(null);
    const [authenticated, setAuthenticated] = useState(false);
    const [message, setMessage] = useState('');

    useEffect(() => {
        const initKeycloak = async () => {
            const authenticated = await keycloakClient.init({ onLoad: 'login-required' });

            setKeycloak(keycloakClient);
            setAuthenticated(authenticated);
        };

        initKeycloak();
    }, []);

    const fetchPublicData = async () => {
        const response = await axios.get('http://localhost:8081/public');
        setMessage(response.data.message);
    };

    const fetchPrivateData = async () => {
        if (!keycloak) return;
        try {
            const response = await axios.get('http://localhost:8081/private', {
                headers: { Authorization: `Bearer ${keycloak.token}` },
            });
            setMessage(response.data.message);
        } catch (error) {
            setMessage('Access Denied');
        }
    };

    return (
        <div>
            {keycloak ? (
                authenticated ? (
                    <div>
                        <h1>Welcome {keycloak.tokenParsed.preferred_username}</h1>
                        <button onClick={fetchPublicData}>Public Data</button>
                        <button onClick={fetchPrivateData}>Private Data</button>
                        <button onClick={() => keycloak.logout()}>Logout</button>
                        <p>{message}</p>
                    </div>
                ) : (
                    <h2>Unable to authenticate!</h2>
                )
            ) : (
                <h2>Initializing Keycloak...</h2>
            )}
        </div>
    );
}

export default App;
