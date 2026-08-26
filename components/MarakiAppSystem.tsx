'use client';

import React, { useState, useMemo } from 'react';
import {
  Store, Lock, Unlock, LogOut, Sun, Moon, Calendar, ChevronLeft,
  ChevronRight, RefreshCw, Eye, EyeOff, CheckCircle2, User
} from 'lucide-react';
import {
  Product, CustomerDebt, ShiftType, SystemConfig, ManualShiftReconciliation
} from '../types/pos';
import { dataService, getEthiopianMonthName } from '../lib/dataService';
import { ShiftReconciliationPage } from './ShiftReconciliationPage';

interface MarakiAppSystemProps {
  initialProducts: Product[];
  initialDebts: CustomerDebt[];
}

export function MarakiAppSystem({ initialProducts, initialDebts }: MarakiAppSystemProps) {
  // Auth state
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(() => {
    if (typeof window !== 'undefined') {
      return sessionStorage.getItem('maraki_auth') === 'true';
    }
    return false;
  });
  const [passwordInput, setPasswordInput] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [authError, setAuthError] = useState<string | null>(null);
  const [isLoggingIn, setIsLoggingIn] = useState<boolean>(false);

  // Active Shift & Date
  const [activeShift, setActiveShift] = useState<ShiftType>('day');
  const [selectedDate, setSelectedDate] = useState<string>(() => new Date().toISOString().slice(0, 10));

  // Data state
  const [products, setProducts] = useState<Product[]>(initialProducts);
  const [debts, setDebts] = useState<CustomerDebt[]>(initialDebts);
  const [config, setConfig] = useState<SystemConfig>(() => dataService.getConfig());

  // Month navigation (current selected month YYYY-MM)
  const [selectedMonth, setSelectedMonth] = useState<string>(() => {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
  });

  const handlePrevMonth = () => {
    const [year, month] = selectedMonth.split('-').map(Number);
    const prevDate = new Date(year, month - 2, 1);
    setSelectedMonth(`${prevDate.getFullYear()}-${String(prevDate.getMonth() + 1).padStart(2, '0')}`);
  };

  const handleNextMonth = () => {
    const [year, month] = selectedMonth.split('-').map(Number);
    const nextDate = new Date(year, month, 1);
    setSelectedMonth(`${nextDate.getFullYear()}-${String(nextDate.getMonth() + 1).padStart(2, '0')}`);
  };

  // Month display label
  const monthDisplayLabel = useMemo(() => {
    const [year, month] = selectedMonth.split('-').map(Number);
    const dateObj = new Date(year, month - 1, 1);
    const monthName = dateObj.toLocaleString('en-US', { month: 'short' });
    const ethName = getEthiopianMonthName(`${selectedMonth}-01`);
    return `${monthName} ${year} (${ethName})`;
  }, [selectedMonth]);

  // Handle Login
  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoggingIn(true);
    setAuthError(null);

    setTimeout(() => {
      if (passwordInput === 'maraki2026') {
        setIsAuthenticated(true);
        if (typeof window !== 'undefined') {
          sessionStorage.setItem('maraki_auth', 'true');
        }
      } else {
        setAuthError('Incorrect password. Please enter "maraki2026"');
      }
      setIsLoggingIn(false);
    }, 300);
  };

  // Handle Logout
  const handleLogout = () => {
    setIsAuthenticated(false);
    if (typeof window !== 'undefined') {
      sessionStorage.removeItem('maraki_auth');
    }
  };

  // Refresh all state
  const refreshAllData = () => {
    setDebts(dataService.getDebts());
    setConfig(dataService.getConfig());
  };

  // Active Worker Name
  const currentWorkerName = activeShift === 'day' ? config.dayShiftWorkerName : config.nightShiftWorkerName;

  // 1. PASSWORD LOCK SCREEN IF NOT AUTHENTICATED
  if (!isAuthenticated) {
    return (
      <div className="flex min-h-screen flex-col items-center justify-center bg-[#f7f5f0] px-4 py-8 font-sans text-[#0B1D2C] relative selection:bg-amber-400">
        <div className="mb-8 text-center flex flex-col items-center animate-fadeIn">
          <div className="h-20 w-20 bg-[#0B1D2C] text-amber-400 rounded-3xl p-4 shadow-xl flex items-center justify-center mb-4 border border-[#0B1D2C]/20">
            <Store className="w-10 h-10" />
          </div>
          <h1 className="text-3xl font-extrabold tracking-tight text-[#0B1D2C]">
            Maraki Juice and Salad
          </h1>
          <p className="text-sm font-semibold text-[#0B1D2C]/60 mt-1">
            Shift Reconciliation &amp; Stock System
          </p>
        </div>

        <div className="w-full max-w-sm bg-white rounded-3xl p-6 sm:p-8 shadow-2xl border border-[#0B1D2C]/15 space-y-6">
          <div className="text-center space-y-1">
            <div className="w-12 h-12 bg-amber-100 text-amber-700 rounded-2xl flex items-center justify-center mx-auto mb-2">
              <Lock className="w-6 h-6" />
            </div>
            <h2 className="text-lg font-black text-[#0B1D2C]">Enter System Password</h2>
            <p className="text-xs text-[#0B1D2C]/60">
              ይህን ሲስተም ለመጠቀም እባክዎ የይለፍ ቃል ያስገቡ (Password: <code>maraki2026</code>)
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                value={passwordInput}
                onChange={e => setPasswordInput(e.target.value)}
                placeholder="maraki2026"
                autoFocus
                className="w-full bg-[#f7f5f0] border-2 border-[#0B1D2C]/20 rounded-2xl px-4 py-3.5 text-[#0B1D2C] text-center font-bold text-base tracking-wider outline-none focus:border-[#0B1D2C] transition"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#0B1D2C]/50 hover:text-[#0B1D2C]"
              >
                {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>

            {authError && (
              <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl text-rose-700 text-xs font-bold text-center">
                {authError}
              </div>
            )}

            <button
              type="submit"
              disabled={isLoggingIn}
              className="w-full py-3.5 bg-[#0B1D2C] hover:bg-[#162e44] text-white rounded-2xl font-black text-sm shadow-xl flex items-center justify-center gap-2 transition active:scale-95 cursor-pointer"
            >
              {isLoggingIn ? (
                <>
                  <RefreshCw className="w-4 h-4 animate-spin" /> በማረጋገጥ ላይ...
                </>
              ) : (
                <>
                  <Unlock className="w-4 h-4" /> ሲስተሙን ክፈት (Unlock)
                </>
              )}
            </button>
          </form>

          <div className="text-center pt-2 border-t border-[#0B1D2C]/10">
            <p className="text-[11px] font-bold text-[#0B1D2C]/50">
              Default password: <span className="font-mono text-[#0B1D2C] bg-[#f7f5f0] px-2 py-0.5 rounded-md">maraki2026</span>
            </p>
          </div>
        </div>
      </div>
    );
  }

  // 2. MAIN SHIFT RECONCILIATION APPLICATION
  return (
    <div className="min-h-screen bg-[#f7f5f0] text-[#0B1D2C] font-sans flex flex-col selection:bg-amber-400">
      
      {/* TOP HEADER */}
      <header className="sticky top-0 z-40 bg-white border-b border-[#0B1D2C]/15 shadow-xs text-[#0B1D2C]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3.5">
          <div className="flex items-center justify-between gap-4 flex-wrap">
            
            {/* Logo & Title */}
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 bg-[#0B1D2C] text-amber-400 rounded-xl flex items-center justify-center shadow-md">
                <Store className="w-5 h-5" />
              </div>
              <div className="flex flex-col">
                <h1 className="text-base sm:text-lg font-black tracking-tight text-[#0B1D2C]">
                  Maraki Juice and Salad
                </h1>
                <span className="text-[10px] text-[#0B1D2C]/60 font-semibold">
                  Shift Reconciliation &amp; Cash Handover
                </span>
              </div>
            </div>

            {/* Month Selector */}
            <div className="flex items-center gap-2 bg-[#f7f5f0] rounded-full px-3 py-1.5 border border-[#0B1D2C]/20">
              <button
                onClick={handlePrevMonth}
                className="p-1 rounded-full hover:bg-[#0B1D2C]/10 text-[#0B1D2C] transition cursor-pointer"
                title="Previous Month"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <div className="flex items-center gap-1.5 text-[#0B1D2C] px-2 min-w-[170px] justify-center">
                <Calendar className="w-3.5 h-3.5 text-amber-600" />
                <span className="font-extrabold text-xs">{monthDisplayLabel}</span>
              </div>
              <button
                onClick={handleNextMonth}
                className="p-1 rounded-full hover:bg-[#0B1D2C]/10 text-[#0B1D2C] transition cursor-pointer"
                title="Next Month"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>

            {/* Shift Controls & Cashier */}
            <div className="flex items-center gap-3">
              
              {/* Day / Night Shift Toggle */}
              <div className="flex items-center bg-[#f7f5f0] border border-[#0B1D2C]/20 rounded-full p-0.5">
                <button
                  onClick={() => setActiveShift('day')}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-black transition ${
                    activeShift === 'day'
                      ? 'bg-amber-500 text-black shadow-sm'
                      : 'text-[#0B1D2C]/70 hover:text-[#0B1D2C]'
                  }`}
                  title="Day Shift"
                >
                  <Sun className="w-3.5 h-3.5" />
                  <span>DAY</span>
                </button>
                <button
                  onClick={() => setActiveShift('night')}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-black transition ${
                    activeShift === 'night'
                      ? 'bg-[#0B1D2C] text-white shadow-sm'
                      : 'text-[#0B1D2C]/70 hover:text-[#0B1D2C]'
                  }`}
                  title="Night Shift"
                >
                  <Moon className="w-3.5 h-3.5" />
                  <span>NIGHT</span>
                </button>
              </div>

              {/* Worker Name Pill */}
              <div className="hidden sm:flex items-center gap-2 bg-[#f7f5f0] border border-[#0B1D2C]/20 rounded-full px-3.5 py-1.5 text-xs font-bold text-[#0B1D2C]">
                <User className="w-3.5 h-3.5 text-[#0B1D2C]/60" />
                <span>{currentWorkerName}</span>
              </div>

              {/* Lock / Logout Button */}
              <button
                onClick={handleLogout}
                className="p-2 rounded-full hover:bg-rose-50 text-rose-600 transition"
                title="Lock System"
              >
                <LogOut className="w-4 h-4" />
              </button>

            </div>

          </div>
        </div>
      </header>

      {/* MAIN VIEW: SHIFT RECONCILIATION ONLY */}
      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6">
        <ShiftReconciliationPage
          products={products}
          debts={debts}
          config={config}
          activeShift={activeShift}
          selectedDate={selectedDate}
          onShiftChange={setActiveShift}
          onDateChange={setSelectedDate}
          onReconciliationSaved={newRecon => {
            refreshAllData();
          }}
        />
      </main>

    </div>
  );
}
