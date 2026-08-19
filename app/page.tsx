'use client';

import React, { useState, useEffect } from 'react';
import './workflow.css';
import { AppMode, ShiftType, Product, Order, CustomerDebt, ShiftSession, ShiftReconciliation, KitchenTicket } from '../types/pos';
import { dataService, INITIAL_PRODUCTS, INITIAL_DEBTS } from '../lib/dataService';
import { ShiftGate } from '../components/ShiftGate';
import { CupSetup } from '../components/CupSetupModal';
import { POSWorkspace } from '../components/POSWorkspace';
import { KitchenWorkspace } from '../components/KitchenWorkspace';
import { AdminDashboard } from '../components/AdminDashboard';

export default function Page() {
  const [mode, setMode] = useState<AppMode>('gate');
  const [shiftType, setShiftType] = useState<ShiftType | null>(null);

  // Active Shift Session
  const [shiftSession, setShiftSession] = useState<ShiftSession | null>(null);

  // Core App Data
  const [products, setProducts] = useState<Product[]>(INITIAL_PRODUCTS);
  const [orders, setOrders] = useState<Order[]>([]);
  const [debts, setDebts] = useState<CustomerDebt[]>(INITIAL_DEBTS);
  const [completedReconciliations, setCompletedReconciliations] = useState<ShiftReconciliation[]>([]);
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

    // If there's already an active session for this shift type, just return to it
    // (orders are preserved — nothing is reset)
    if (shiftSession && shiftSession.shiftType === chosenShift && shiftSession.status === 'active') {
      setMode('pos');
      return;
    }

    // Always require physical cup verification for any new shift entry
    setMode('cups');
  };

  // Start Shift Session after cup setup (first time today only)
  const handleStartShiftSession = (openingCupsCount: number) => {
    if (!shiftType) return;
    dataService.markCupSetupDoneToday();
    const newSession: ShiftSession = {
      id: `shift-${Date.now()}`,
      shiftType,
      cashierName: 'Sara Mekonnen',
      openingCups: openingCupsCount,
      status: 'active',
      startedAt: new Date().toISOString(),
    };
    setShiftSession(newSession);
    setOrders([]); // Fresh session — reset orders only on genuine first start
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

  // End Shift Close Callback from Reconciliation Wizard
  const handleCloseShift = () => {
    setShiftSession(null);
    setMode('gate');
  };

  // Render view depending on mode
  if (mode === 'gate') {
    return (
      <ShiftGate
        onSelectShift={handleSelectShift}
        onSelectKitchen={() => setMode('kitchen')}
        onSelectAdmin={() => setMode('admin')}
      />
    );
  }

  if (mode === 'cups' && shiftType) {
    return (
      <CupSetup
        shift={shiftType}
        onBack={() => setMode('gate')}
        onStart={handleStartShiftSession}
      />
    );
  }

  if (mode === 'kitchen') {
    return (
      <KitchenWorkspace
        products={products}
        onBack={() => setMode('gate')}
        onTicketSent={(ticket) => setKitchenTickets(prev => [ticket, ...prev])}
      />
    );
  }

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

  return (
    <ShiftGate
      onSelectShift={handleSelectShift}
      onSelectKitchen={() => setMode('kitchen')}
      onSelectAdmin={() => setMode('admin')}
    />
  );
}
