import React, { useState, useEffect } from 'react';
import keycloakClient from './keycloak';
import axios from 'axios';


const App = () => {
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [loading, setLoading] = useState(true);
    const [message, setMessage] = useState('');


    useEffect(() => {
        keycloakClient.initPromise
            .then(authenticated => {
                setIsAuthenticated(authenticated);
                setLoading(false);
            })
            .catch(error => {
                console.error("Keycloak initialization failed", error);
                setLoading(false);
            });
    }, []);

    const login = () => keycloakClient.login();
    const logout = () => keycloakClient.logout();

    const fetchPublicData = async () => {
        const response = await axios.get('http://localhost:8081/public');
        setMessage(response.data.message);
    };

    const fetchPrivateData = async () => {
        if (!keycloakClient) return;
        try {
            const response = await axios.get('http://localhost:8081/private', {
                headers: { Authorization: `Bearer ${keycloakClient.token}` },
            });
            setMessage(response.data.message);
        } catch (error) {
            setMessage('Access Denied');
        }
    };

    if (loading) return <div>Loading...</div>;

    return (
        <div>
            <h1>Welcome to webapp</h1>
            {isAuthenticated ? (
                <div>
                    <h3>Welcome, {keycloakClient.tokenParsed?.preferred_username}!</h3>
                    <button onClick={fetchPublicData}>Public Data</button>
                    <button onClick={fetchPrivateData}>Private Data</button>
                    <button onClick={logout}>Logout</button>
                    <p>{message}</p>
                </div>
            ) : (
                <button onClick={login}>Login with Keycloak</button>
            )}
        </div>
    );
};

export default App;