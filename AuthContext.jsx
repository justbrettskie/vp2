import React, { createContext, useState, useContext, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabase';

const AuthContext = createContext(null);
export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoadingAuth, setIsLoadingAuth] = useState(true);
  const [isLoadingPublicSettings, setIsLoadingPublicSettings] = useState(false);
  const [authError, setAuthError] = useState(null);
  const [authChecked, setAuthChecked] = useState(false);
  const [appPublicSettings] = useState(null);

  const checkUserAuth = useCallback(async () => {
    setIsLoadingAuth(true); setAuthError(null);
    const { data, error } = await supabase.auth.getUser();
    if (error && error.name !== 'AuthSessionMissingError') setAuthError({ type: 'auth_required', message: error.message });
    const current = data?.user ?? null;
    setUser(current ? { id: current.id, email: current.email, ...current.user_metadata, role: current.role } : null);
    setIsAuthenticated(!!current); setIsLoadingAuth(false); setAuthChecked(true);
  }, []);

  useEffect(() => {
    checkUserAuth();
    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      const current = session?.user ?? null;
      setUser(current ? { id: current.id, email: current.email, ...current.user_metadata, role: current.role } : null);
      setIsAuthenticated(!!current); setIsLoadingAuth(false); setAuthChecked(true);
    });
    return () => listener.subscription.unsubscribe();
  }, [checkUserAuth]);

  const logout = async (shouldRedirect = true) => {
    const { error } = await supabase.auth.signOut(); if (error) throw error;
    if (shouldRedirect) window.location.assign('/Login');
  };
  const navigateToLogin = () => window.location.assign('/Login');
  const checkAppState = checkUserAuth;

  return <AuthContext.Provider value={{ user, isAuthenticated, isLoadingAuth, isLoadingPublicSettings, authError, appPublicSettings, authChecked, logout, navigateToLogin, checkUserAuth, checkAppState }}>{children}</AuthContext.Provider>;
};
export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within an AuthProvider');
  return context;
};
