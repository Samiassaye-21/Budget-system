'use client';

import React, { useState, useEffect } from 'react';
import './workflow.css';
import {
  AppMode, ShiftType, Product, Order, CustomerDebt, ShiftSession,
  ShiftReconciliation, KitchenTicket
} from '../types/pos';
import { dataService, INITIAL_PRODUCTS, INITIAL_DEBTS } from '../lib/dataService';
import { ShiftGate } from '../components/ShiftGate';
import { CupSetup } from '../components/CupSetupModal';
import { POSWorkspace } from '../components/POSWorkspace';
import { KitchenWorkspace } from '../components/KitchenWorkspace';
import { AdminDashboard } from '../components/AdminDashboard';
import { MarakiAppSystem } from '../components/MarakiAppSystem';

export default function Page() {
  const [mode, setMode] = useState<AppMode>('gate');
  const [shiftType, setShiftType] = useState<ShiftType | null>(null);

  // Active Shift Session
  const [shiftSession, setShiftSession] = useState<ShiftSession | null>(null);

  // Core App Data
  const [products, setProducts] = useState<Product[]>(INITIAL_PRODUCTS);
  const [orders, setOrders] = useState<Order[]>([]);
  const [debts, setDebts] = useState<CustomerDebt[]>(INITIAL_DEBTS);
  const [kitchenTickets, setKitchenTickets] = useState<KitchenTicket[]>([]);

  // Load initial products & customer debts from dataService (Supabase or local fallback)
  useEffect(() => {
    async function loadData() {
      try {
        const fetchedProducts = await dataService.getProducts();
        setProducts(fetchedProducts);
        const fetchedDebts = await dataService.getCustomerDebts();
        setDebts(fetchedDebts);
        const fetchedTickets = dataService.getKitchenTickets();
        setKitchenTickets(fetchedTickets);
      } catch (err) {
        console.error('Error initializing data from service:', err);
      }
    }
    loadData();
  }, []);

  // Handlers for Shift Gate selection
  const handleSelectShift = (chosenShift: ShiftType) => {
    setShiftType(chosenShift);

    // If there's already an active session for this shift type, return to it
    if (shiftSession && shiftSession.shiftType === chosenShift && shiftSession.status === 'active') {
      setMode('pos');
      return;
    }

    // Physical cup verification for new shift entry
    setMode('cups');
  };

  // Start Shift Session after cup setup
  const handleStartShiftSession = (openingCupsCount: number) => {
    if (!shiftType) return;
    dataService.markCupSetupDoneToday();
    const config = dataService.getConfig();
    const cashierName = shiftType === 'day' ? config.dayShiftWorkerName : config.nightShiftWorkerName;

    const newSession: ShiftSession = {
      id: `shift-${Date.now()}`,
      shiftType,
      cashierName,
      openingCups: openingCupsCount,
      status: 'active',
      startedAt: new Date().toISOString(),
    };
    setShiftSession(newSession);
    setOrders([]);
    setMode('pos');
  };

  // Toggle Product Stock Availability
  const handleToggleAvailability = async (productId: string) => {
    setProducts(prev =>
      prev.map(p => {
        if (p.id === productId) {
          const updated = { ...p, isAvailable: !p.isAvailable };
          dataService.saveProduct(updated);
          return updated;
        }
        return p;
      })
    );
  };

  // Add / Save Product in Admin
  const handleSaveProduct = async (product: Product) => {
    const saved = await dataService.saveProduct(product);
    setProducts(prev => {
      const idx = prev.findIndex(p => p.id === saved.id || p.name === saved.name);
      if (idx >= 0) {
        const copy = [...prev];
        copy[idx] = saved;
        return copy;
      }
      return [...prev, saved];
    });
  };

  // Fire Order
  const handleFireOrder = async (order: Order) => {
    setOrders(prev => [order, ...prev]);
    await dataService.saveOrder(order);
  };

  // Update Orders (e.g. after Pay Later resolution)
  const handleUpdateOrders = (updatedOrdersList: Order[]) => {
    setOrders(prev => {
      const copy = [...prev];
      updatedOrdersList.forEach(uo => {
        const idx = copy.findIndex(o => o.id === uo.id);
        if (idx >= 0) {
          copy[idx] = uo;
        } else {
          copy.push(uo);
        }
      });
      return copy;
    });
  };

  // Add Debts (e.g. from Pay Later orders resolved to Pending Payment / Credit)
  const handleAddDebts = (newDebtsList: CustomerDebt[]) => {
    setDebts(prev => [...newDebtsList, ...prev]);
  };

  // End Shift Close Callback from Reconciliation
  const handleCloseShift = () => {
    setShiftSession(null);
    setMode('gate');
  };

  // 1. Shift Gate (Workspace Selector)
  if (mode === 'gate') {
    return (
      <ShiftGate
        onSelectShift={handleSelectShift}
        onSelectKitchen={() => setMode('kitchen')}
        onSelectAdmin={() => setMode('admin')}
        onSelectManualRecon={() => setMode('manual-recon')}
      />
    );
  }

  // 2. Physical Cup Setup Modal
  if (mode === 'cups' && shiftType) {
    return (
      <CupSetup
        shift={shiftType}
        onBack={() => setMode('gate')}
        onStart={handleStartShiftSession}
      />
    );
  }

  // 3. Kitchen Display Workspace
  if (mode === 'kitchen') {
    return (
      <KitchenWorkspace
        products={products}
        onBack={() => setMode('gate')}
        onTicketSent={ticket => setKitchenTickets(prev => [ticket, ...prev])}
      />
    );
  }

  // 4. Admin Dashboard
  if (mode === 'admin') {
    return (
      <AdminDashboard
        products={products}
        orders={orders}
        debts={debts}
        onSaveProduct={handleSaveProduct}
        onToggleAvailability={handleToggleAvailability}
        onBack={() => setMode('gate')}
      />
    );
  }

  // 5. Full POS Touchscreen Workspace
  if (mode === 'pos' && shiftSession) {
    return (
      <POSWorkspace
        shiftSession={shiftSession}
        products={products}
        orders={orders}
        debts={debts}
        onToggleAvailability={handleToggleAvailability}
        onFireOrder={handleFireOrder}
        onUpdateOrders={handleUpdateOrders}
        onAddDebts={handleAddDebts}
        onCloseShift={handleCloseShift}
        onSwitchWorkspace={() => setMode('gate')}
      />
    );
  }

  // 6. Dedicated Shift Reconciliation Subsystem (Exact Maraki 5-Part Engine)
  return (
    <MarakiAppSystem
      initialProducts={products}
      initialDebts={debts}
      onBackToGate={() => setMode('gate')}
    />
  );
}
