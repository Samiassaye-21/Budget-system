'use client';

import React, { useState, useMemo, useEffect } from 'react';
import {
  Calendar, Sun, Moon, Plus, Minus, Check, X, ShieldCheck,
  AlertTriangle, Info, Lock, Smartphone, Calculator, Receipt,
  Clock, Truck, CheckCircle2, ChevronDown, RefreshCw, Trash2,
  FileSpreadsheet, ArrowRight
} from 'lucide-react';
import {
  Product, CustomerDebt, ShiftType, SystemConfig, TransferRecord,
  ShiftExpense, ManualShiftReconciliation
} from '../types/pos';
import { dataService } from '../lib/dataService';

interface ShiftReconciliationPageProps {
  products: Product[];
  debts: CustomerDebt[];
  config: SystemConfig;
  activeShift: ShiftType;
  selectedDate: string;
  onShiftChange: (shift: ShiftType) => void;
  onDateChange: (date: string) => void;
  onReconciliationSaved?: (recon: ManualShiftReconciliation) => void;
}

export function ShiftReconciliationPage({
  products,
  debts,
  config,
  activeShift,
  selectedDate,
  onShiftChange,
  onDateChange,
  onReconciliationSaved,
}: ShiftReconciliationPageProps) {
  // Worker name based on shift
  const currentWorkerName = activeShift === 'day' ? config.dayShiftWorkerName : config.nightShiftWorkerName;

  // --- SECTION 1: JUICE & SMOOTHIE CUPS ---
  const [juiceOpening, setJuiceOpening] = useState<number>(25);
  const [juiceAdded, setJuiceAdded] = useState<number>(0);
  const [juiceLeftover, setJuiceLeftover] = useState<number>(0);

  const juiceSold = Math.max(0, (juiceOpening + juiceAdded) - juiceLeftover);
  const juiceUnitPrice = config.juiceUnitPrice || 170;
  const juiceRevenue = juiceSold * juiceUnitPrice;

  // --- SECTION 1: FOOD TAKEAWAY SALES ---
  const [foodCalcMethod, setFoodCalcMethod] = useState<'itemized' | 'flat'>('itemized');
  const [foodOpening, setFoodOpening] = useState<number>(9);
  const [foodAdded, setFoodAdded] = useState<number>(0);
  const [foodLeftover, setFoodLeftover] = useState<number>(0);

  const totalBoxesSoldPhysical = Math.max(0, (foodOpening + foodAdded) - foodLeftover);

  // Food catalog items for itemization
  const foodProducts = useMemo(() => products.filter(p => p.category === 'Food'), [products]);
  const [foodItemQuantities, setFoodItemQuantities] = useState<{ [name: string]: number }>({});
  const [includeUnitemizedBoxes, setIncludeUnitemizedBoxes] = useState<boolean>(true);

  const totalItemizedBoxes = useMemo(() => {
    return Object.values(foodItemQuantities).reduce((sum, q) => sum + (Number(q) || 0), 0);
  }, [foodItemQuantities]);

  const unitemizedBoxesCount = Math.max(0, totalBoxesSoldPhysical - totalItemizedBoxes);

  const itemizedFoodRevenue = useMemo(() => {
    let rev = 0;
    foodProducts.forEach(p => {
      const q = foodItemQuantities[p.name] || 0;
      rev += q * p.price;
    });
    // If include un-itemized boxes is checked, apply estimated average dish price (320 ETB)
    if (includeUnitemizedBoxes && unitemizedBoxesCount > 0) {
      rev += unitemizedBoxesCount * 320;
    }
    return rev;
  }, [foodProducts, foodItemQuantities, includeUnitemizedBoxes, unitemizedBoxesCount]);

  const foodRevenue = foodCalcMethod === 'itemized'
    ? itemizedFoodRevenue
    : totalBoxesSoldPhysical * 320;

  // GROSS REVENUE
  const grossRevenue = juiceRevenue + foodRevenue;

  // --- SECTION 2: CASH DEDUCTIONS & ADDITIONS ---

  // 1. Digital Transfers
  const [transfers, setTransfers] = useState<TransferRecord[]>([
    { id: 'tf-1', senderName: '', amount: 0, note: 'Telebirr' }
  ]);
  const [isTransferModalOpen, setIsTransferModalOpen] = useState<boolean>(false);
  const digitalTransfersTotal = useMemo(() => {
    return transfers.reduce((sum, t) => sum + (Number(t.amount) || 0), 0);
  }, [transfers]);

  // 2. Daily Cooking Expenses
  const [expenses, setExpenses] = useState<ShiftExpense[]>([
    { id: 'exp-1', shiftId: 'shift', category: 'Kitchen supplies', description: '', amount: 0, loggedAt: new Date().toISOString() }
  ]);
  const [isExpenseModalOpen, setIsExpenseModalOpen] = useState<boolean>(false);
  const dailyExpensesTotal = useMemo(() => {
    return expenses.reduce((sum, e) => sum + (Number(e.amount) || 0), 0);
  }, [expenses]);

  // 3. New Unpaid Pending Credit (Adari)
  const [newPendingCustomerName, setNewPendingCustomerName] = useState<string>('');
  const [newPendingJuiceCups, setNewPendingJuiceCups] = useState<number>(0);
  const [newPendingFoodItems, setNewPendingFoodItems] = useState<{ [name: string]: number }>({});

  const newPendingCreditTotal = useMemo(() => {
    let tot = newPendingJuiceCups * juiceUnitPrice;
    foodProducts.forEach(p => {
      const q = newPendingFoodItems[p.name] || 0;
      tot += q * p.price;
    });
    return tot;
  }, [newPendingJuiceCups, juiceUnitPrice, foodProducts, newPendingFoodItems]);

  // 4. Recovered Past Pending Debts
  const [selectedDebtsFull, setSelectedDebtsFull] = useState<{ [id: string]: boolean }>({});
  const [selectedDebtsPartialCups, setSelectedDebtsPartialCups] = useState<{ [id: string]: number }>({});
  const [extraUnlistedRecoveredJuice, setExtraUnlistedRecoveredJuice] = useState<number>(0);
  const [extraUnlistedRecoveredFood, setExtraUnlistedRecoveredFood] = useState<{ [name: string]: number }>({});
  const [recoveredCustomNote, setRecoveredCustomNote] = useState<string>('');

  const activeUnpaidDebts = useMemo(() => {
    return debts.filter(d => !d.isRecovered);
  }, [debts]);

  const recoveredDebtsTotal = useMemo(() => {
    let tot = 0;
    activeUnpaidDebts.forEach(d => {
      if (selectedDebtsFull[d.id]) {
        tot += d.amount;
      } else {
        const partialCups = selectedDebtsPartialCups[d.id] || 0;
        tot += partialCups * d.pricePerCup;
      }
    });
    tot += extraUnlistedRecoveredJuice * juiceUnitPrice;
    foodProducts.forEach(p => {
      const q = extraUnlistedRecoveredFood[p.name] || 0;
      tot += q * p.price;
    });
    return tot;
  }, [activeUnpaidDebts, selectedDebtsFull, selectedDebtsPartialCups, extraUnlistedRecoveredJuice, juiceUnitPrice, foodProducts, extraUnlistedRecoveredFood]);

  // 5. Delivery Rider Credit Orders
  const [deliveryCups, setDeliveryCups] = useState<number>(0);
  const [deliveryBoxes, setDeliveryBoxes] = useState<number>(0);
  const [deliveryPartnerName, setDeliveryPartnerName] = useState<string>('BeU Delivery');

  const deliveryDeductionTotal = useMemo(() => {
    return (deliveryCups * juiceUnitPrice) + (deliveryBoxes * 320);
  }, [deliveryCups, juiceUnitPrice, deliveryBoxes]);

  // --- FINAL PHYSICAL CASH HANDOVER FORMULA ---
  // Net Cash = Gross - Digital - Exp - New Pending + Recovered - Delivery
  const netCashDueToOwner = Math.max(
    0,
    grossRevenue - digitalTransfersTotal - dailyExpensesTotal - newPendingCreditTotal + recoveredDebtsTotal - deliveryDeductionTotal
  );

  // Shift Notes
  const [shiftNotes, setShiftNotes] = useState<string>('');
  const [isPinModalOpen, setIsPinModalOpen] = useState<boolean>(false);
  const [pinInput, setPinInput] = useState<string>('');
  const [pinError, setPinError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [saveSuccessMessage, setSaveSuccessMessage] = useState<string | null>(null);

  // Handlers for dynamic lists
  const handleAddTransfer = () => {
    setTransfers(prev => [...prev, { id: `tf-${Date.now()}`, senderName: '', amount: 0, note: 'Telebirr' }]);
  };
  const handleRemoveTransfer = (id: string) => {
    setTransfers(prev => prev.filter(t => t.id !== id));
  };
  const handleUpdateTransfer = (id: string, field: keyof TransferRecord, val: any) => {
    setTransfers(prev => prev.map(t => t.id === id ? { ...t, [field]: field === 'amount' ? Number(val) || 0 : val } : t));
  };

  const handleAddExpense = () => {
    setExpenses(prev => [...prev, { id: `exp-${Date.now()}`, shiftId: 'shift', category: 'Kitchen supplies', description: '', amount: 0, loggedAt: new Date().toISOString() }]);
  };
  const handleRemoveExpense = (id: string) => {
    setExpenses(prev => prev.filter(e => e.id !== id));
  };
  const handleUpdateExpense = (id: string, field: keyof ShiftExpense, val: any) => {
    setExpenses(prev => prev.map(e => e.id === id ? { ...e, [field]: field === 'amount' ? Number(val) || 0 : val } : e));
  };

  // Submit Shift Reconciliation
  const handleConfirmCloseShift = async () => {
    if (pinInput !== '1234' && pinInput !== 'maraki2026' && pinInput.length < 4) {
      setPinError('Invalid PIN. Use 1234 or your 4-digit shift PIN.');
      return;
    }

    setIsSubmitting(true);
    setPinError(null);

    try {
      const recon: ManualShiftReconciliation = {
        id: `recon-${Date.now()}`,
        shiftId: `shift-${selectedDate}-${activeShift}`,
        shiftType: activeShift,
        cashierName: currentWorkerName,
        entryMode: 'manual',
        shiftDate: selectedDate,
        grossRevenue,
        cashSales: Math.max(0, grossRevenue - digitalTransfersTotal - newPendingCreditTotal - deliveryDeductionTotal),
        transferSales: digitalTransfersTotal,
        creditSales: newPendingCreditTotal,
        deliverySales: deliveryDeductionTotal,
        tipSales: 0,
        totalOrdersCount: juiceSold + totalBoxesSoldPhysical,
        openingCups: juiceOpening,
        addedCups: juiceAdded,
        leftoverCups: juiceLeftover,
        calculatedCupsSold: juiceSold,
        tabletCupsSold: juiceSold,
        cupsVariance: 0,
        totalKitchenFoodCooked: totalBoxesSoldPhysical,
        totalWaiterFoodSold: totalItemizedBoxes,
        foodVariance: totalItemizedBoxes - totalBoxesSoldPhysical,
        foodItemsReconciliation: foodProducts.map(p => ({
          id: p.name,
          name: p.name,
          emoji: p.emoji,
          kitchenCookedCount: foodItemQuantities[p.name] || 0,
          waiterSoldCount: foodItemQuantities[p.name] || 0,
          variance: 0
        })),
        totalExpenses: dailyExpensesTotal,
        expenses: expenses.filter(e => e.amount > 0),
        totalRecoveredCups: Math.round(recoveredDebtsTotal / juiceUnitPrice),
        totalRecoveredDebts: recoveredDebtsTotal,
        recoveredDebts: activeUnpaidDebts.filter(d => selectedDebtsFull[d.id]),
        netCashToOwner: netCashDueToOwner,
        shiftNotes,
        closedAt: new Date().toISOString(),
        juiceBreakdown: [],
        foodBoxInventory: [],
        foodSoldBreakdown: [],
        transferRecords: transfers.filter(t => t.amount > 0),
        pendingPayments: newPendingCreditTotal > 0 ? [{
          id: `deb-new-${Date.now()}`,
          customerName: newPendingCustomerName || 'Unassigned Debtor',
          amount: newPendingCreditTotal,
          note: `${newPendingJuiceCups} cups + food credit`
        }] : [],
        recoveredPayments: [],
        kitchenDataFound: false
      };

      await dataService.saveManualReconciliation(recon);

      // If new pending debtor was created, save to debt ledger
      if (newPendingCreditTotal > 0 && newPendingCustomerName.trim()) {
        dataService.createDebt({
          id: `deb-${Date.now()}`,
          customerName: newPendingCustomerName.trim(),
          note: `Credit from ${selectedDate} ${activeShift} shift`,
          cupCount: newPendingJuiceCups,
          pricePerCup: juiceUnitPrice,
          amount: newPendingCreditTotal,
          isRecovered: false,
          shiftIdCreated: `shift-${selectedDate}-${activeShift}`,
          createdAt: new Date().toISOString()
        });
      }

      setIsPinModalOpen(false);
      setSaveSuccessMessage('Shift Reconciliation Saved & Synced Successfully!');
      if (onReconciliationSaved) {
        onReconciliationSaved(recon);
      }
      setTimeout(() => setSaveSuccessMessage(null), 4000);
    } catch (err) {
      console.error('Error saving shift reconciliation:', err);
      setPinError('Error saving shift. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="space-y-8 animate-fadeIn text-[#0B1D2C]">
      
      {/* Toast Alert on Success */}
      {saveSuccessMessage && (
        <div className="p-4 bg-emerald-100 border border-emerald-300 rounded-2xl text-emerald-900 text-xs font-black flex items-center justify-between shadow-lg">
          <span className="flex items-center gap-2">
            <CheckCircle2 className="w-5 h-5 text-emerald-600" />
            {saveSuccessMessage}
          </span>
          <button onClick={() => setSaveSuccessMessage(null)} className="text-emerald-700 font-bold">✕</button>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 1. STOCK INVENTORY COUNT */}
      {/* ========================================================================= */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <span className="w-7 h-7 bg-[#0B1D2C] text-white rounded-full flex items-center justify-center font-black text-xs">
              1
            </span>
            <h2 className="text-lg font-black tracking-tight text-[#0B1D2C]">
              Stock Inventory Count
            </h2>
          </div>
          <span className="px-3 py-1 bg-[#0B1D2C] text-amber-400 rounded-full text-xs font-black flex items-center gap-1.5 shadow-xs">
            ⚡ Auto-Calculates
          </span>
        </div>

        {/* 2-Column Cards Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">
          
          {/* LEFT CARD: JUICE & SMOOTHIE CUPS */}
          <div className="bg-white rounded-3xl p-6 border border-[#0B1D2C]/15 shadow-xs space-y-5">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="p-2 bg-[#f7f5f0] text-[#0B1D2C] rounded-xl border border-[#0B1D2C]/10">
                  🥤
                </div>
                <h3 className="text-sm font-black text-[#0B1D2C]">
                  Juice &amp; Smoothie Cups
                </h3>
              </div>
              <span className="px-3 py-0.5 bg-[#f7f5f0] border border-[#0B1D2C]/15 text-[#0B1D2C] rounded-full text-xs font-extrabold">
                {juiceUnitPrice} Br / cup
              </span>
            </div>

            {/* 3-Pill Inputs Row */}
            <div className="grid grid-cols-3 gap-3 text-center">
              <div>
                <span className="text-[10px] font-black uppercase text-[#0B1D2C]/60 block mb-1">
                  OPENING
                </span>
                <input
                  type="number"
                  value={juiceOpening}
                  onChange={e => setJuiceOpening(Math.max(0, Number(e.target.value) || 0))}
                  className="w-full bg-[#f7f5f0] border-2 border-[#0B1D2C]/20 focus:border-[#0B1D2C] rounded-full py-2.5 text-center font-black text-sm text-[#0B1D2C] outline-none"
                />
                <span className="text-[10px] text-[#0B1D2C]/50 mt-1 block">Last: {juiceOpening}</span>
              </div>

              <div>
                <span className="text-[10px] font-black uppercase text-[#0B1D2C]/60 block mb-1">
                  + ADDED
                </span>
                <input
                  type="number"
                  value={juiceAdded}
                  onChange={e => setJuiceAdded(Math.max(0, Number(e.target.value) || 0))}
                  className="w-full bg-[#f7f5f0] border-2 border-[#0B1D2C]/20 focus:border-[#0B1D2C] rounded-full py-2.5 text-center font-black text-sm text-[#0B1D2C] outline-none"
                />
                <span className="text-[10px] text-[#0B1D2C]/50 mt-1 block">Restocked</span>
              </div>

              <div>
                <span className="text-[10px] font-black uppercase text-[#0B1D2C]/60 block mb-1">
                  LEFTOVER
                </span>
                <input
                  type="number"
                  value={juiceLeftover}
                  onChange={e => setJuiceLeftover(Math.max(0, Number(e.target.value) || 0))}
                  className="w-full bg-white border-2 border-[#0B1D2C] rounded-full py-2.5 text-center font-black text-sm text-[#0B1D2C] outline-none shadow-xs"
                />
                <span className="text-[10px] text-[#0B1D2C]/80 font-bold mt-1 block">Shift End</span>
              </div>
            </div>

            {/* Subtotal Banner */}
            <div className="pt-4 border-t border-[#0B1D2C]/10 flex items-center justify-between text-xs font-bold">
              <span className="text-[#0B1D2C]/70">
                Sold: <strong className="text-[#0B1D2C] font-black">{juiceSold} cups</strong>
              </span>
              <span className="text-[#0B1D2C]/70">
                Revenue: <strong className="text-[#0B1D2C] font-black text-sm">Br {juiceRevenue.toLocaleString('en-US', { minimumFractionDigits: 2 })}</strong>
              </span>
            </div>
          </div>

          {/* RIGHT CARD: FOOD TAKEAWAY SALES */}
          <div className="bg-white rounded-3xl p-6 border border-[#0B1D2C]/15 shadow-xs space-y-5">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="p-2 bg-[#f7f5f0] text-[#0B1D2C] rounded-xl border border-[#0B1D2C]/10">
                  🍽️
                </div>
                <div>
                  <h3 className="text-sm font-black text-[#0B1D2C]">
                    Food Takeaway Sales
                  </h3>
                  <p className="text-[10px] text-[#0B1D2C]/50">Select calculation method below</p>
                </div>
              </div>

              {/* Toggle: Itemized Menu vs Flat Rate */}
              <div className="flex bg-[#f7f5f0] p-0.5 rounded-full border border-[#0B1D2C]/15 text-xs font-black">
                <button
                  type="button"
                  onClick={() => setFoodCalcMethod('itemized')}
                  className={`px-3 py-1 rounded-full transition ${
                    foodCalcMethod === 'itemized'
                      ? 'bg-[#0B1D2C] text-white shadow-xs'
                      : 'text-[#0B1D2C]/60 hover:text-[#0B1D2C]'
                  }`}
                >
                  ✨ Itemized Menu
                </button>
                <button
                  type="button"
                  onClick={() => setFoodCalcMethod('flat')}
                  className={`px-3 py-1 rounded-full transition ${
                    foodCalcMethod === 'flat'
                      ? 'bg-[#0B1D2C] text-white shadow-xs'
                      : 'text-[#0B1D2C]/60 hover:text-[#0B1D2C]'
                  }`}
                >
                  📦 Flat Rate
                </button>
              </div>
            </div>

            {/* Sub-step 1: PHYSICAL BOX COUNT */}
            <div className="bg-[#f7f5f0] rounded-2xl p-4 border border-[#0B1D2C]/10 space-y-3">
              <div className="flex items-center justify-between text-[11px]">
                <div className="flex items-center gap-1.5 font-black text-[#0B1D2C]">
                  <span className="w-4 h-4 bg-[#0B1D2C] text-white rounded-full flex items-center justify-center text-[9px]">1</span>
                  PHYSICAL BOX COUNT
                </div>
                <span className="text-[10px] text-[#0B1D2C]/60">Opening + Added - Leftover = Sold</span>
              </div>

              <div className="grid grid-cols-3 gap-3 text-center">
                <div>
                  <span className="text-[9px] font-black uppercase text-[#0B1D2C]/60 block mb-1">OPENING</span>
                  <input
                    type="number"
                    value={foodOpening}
                    onChange={e => setFoodOpening(Math.max(0, Number(e.target.value) || 0))}
                    className="w-full bg-white border border-[#0B1D2C]/20 rounded-full py-1.5 text-center font-black text-xs text-[#0B1D2C] outline-none"
                  />
                  <span className="text-[9px] text-[#0B1D2C]/50 mt-0.5 block">Last: {foodOpening}</span>
                </div>
                <div>
                  <span className="text-[9px] font-black uppercase text-[#0B1D2C]/60 block mb-1">+ ADDED</span>
                  <input
                    type="number"
                    value={foodAdded}
                    onChange={e => setFoodAdded(Math.max(0, Number(e.target.value) || 0))}
                    className="w-full bg-white border border-[#0B1D2C]/20 rounded-full py-1.5 text-center font-black text-xs text-[#0B1D2C] outline-none"
                  />
                  <span className="text-[9px] text-[#0B1D2C]/50 mt-0.5 block">Restocked</span>
                </div>
                <div>
                  <span className="text-[9px] font-black uppercase text-[#0B1D2C]/60 block mb-1">LEFTOVER</span>
                  <input
                    type="number"
                    value={foodLeftover}
                    onChange={e => setFoodLeftover(Math.max(0, Number(e.target.value) || 0))}
                    className="w-full bg-white border-2 border-[#0B1D2C] rounded-full py-1.5 text-center font-black text-xs text-[#0B1D2C] outline-none"
                  />
                  <span className="text-[9px] text-[#0B1D2C]/80 font-bold mt-0.5 block">Shift End</span>
                </div>
              </div>

              <div className="pt-2 border-t border-[#0B1D2C]/10 flex items-center justify-between text-xs font-black text-[#0B1D2C]">
                <span>Total Boxes Sold (by count)</span>
                <span className="px-2.5 py-0.5 bg-white rounded-lg border border-[#0B1D2C]/20">{totalBoxesSoldPhysical} boxes</span>
              </div>
            </div>

            {/* Sub-step 2: ITEMIZE WHICH DISHES WERE SOLD (If itemized mode selected) */}
            {foodCalcMethod === 'itemized' && (
              <div className="space-y-3">
                <div className="flex items-center justify-between text-xs">
                  <div className="flex items-center gap-1.5 font-black text-[#0B1D2C]">
                    <span className="w-4 h-4 bg-[#0B1D2C] text-white rounded-full flex items-center justify-center text-[9px]">2</span>
                    ITEMIZE WHICH DISHES WERE SOLD
                  </div>
                  <span className="text-[10px] text-[#0B1D2C]/50">Price auto-applied per item</span>
                </div>

                {/* List of Dishes with Steppers */}
                <div className="max-h-64 overflow-y-auto divide-y divide-[#0B1D2C]/10 pr-1 space-y-1">
                  {foodProducts.map(dish => {
                    const count = foodItemQuantities[dish.name] || 0;
                    return (
                      <div key={dish.id} className="py-2 flex items-center justify-between gap-2 text-xs">
                        <div className="flex-1 min-w-0">
                          <span className="font-bold text-[#0B1D2C] block truncate">{dish.name}</span>
                          <span className="text-[10px] text-[#0B1D2C]/60">{dish.price} Br / order</span>
                        </div>
                        <div className="flex items-center gap-1 bg-[#f7f5f0] border border-[#0B1D2C]/20 rounded-full p-1">
                          <button
                            type="button"
                            onClick={() => setFoodItemQuantities(prev => ({
                              ...prev,
                              [dish.name]: Math.max(0, (prev[dish.name] || 0) - 1)
                            }))}
                            className="w-6 h-6 rounded-full bg-white hover:bg-gray-100 flex items-center justify-center text-[#0B1D2C] font-black text-xs shadow-xs"
                          >
                            <Minus className="w-3 h-3" />
                          </button>
                          <span className="w-8 text-center font-black text-xs">{count}</span>
                          <button
                            type="button"
                            onClick={() => setFoodItemQuantities(prev => ({
                              ...prev,
                              [dish.name]: (prev[dish.name] || 0) + 1
                            }))}
                            className="w-6 h-6 rounded-full bg-[#0B1D2C] hover:bg-[#162e44] flex items-center justify-center text-white font-black text-xs shadow-xs"
                          >
                            <Plus className="w-3 h-3" />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* Itemized vs Physical Reconciliation Badge */}
                <div className="bg-[#f7f5f0] p-3 rounded-2xl border border-[#0B1D2C]/15 space-y-2 text-xs">
                  <div className="flex items-center justify-between font-bold">
                    <span className="text-[#0B1D2C]/70">Itemized dishes</span>
                    <span className="font-black text-[#0B1D2C]">{totalItemizedBoxes} / {totalBoxesSoldPhysical} boxes</span>
                  </div>

                  {unitemizedBoxesCount > 0 && (
                    <div className="p-2.5 bg-amber-50 border border-amber-200 rounded-xl space-y-1.5 text-amber-900 text-[11px]">
                      <div className="flex items-center gap-1.5 font-bold">
                        <AlertTriangle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                        <span>{unitemizedBoxesCount} boxes un-itemized</span>
                        <span className="text-[10px] text-amber-700 ml-auto">(Physical: {totalBoxesSoldPhysical} | Itemized: {totalItemizedBoxes})</span>
                      </div>
                      <label className="flex items-center gap-2 cursor-pointer pt-1 border-t border-amber-200">
                        <input
                          type="checkbox"
                          checked={includeUnitemizedBoxes}
                          onChange={e => setIncludeUnitemizedBoxes(e.target.checked)}
                          className="rounded text-amber-600 focus:ring-amber-500"
                        />
                        <span className="text-[10px] font-semibold">
                          Include {unitemizedBoxesCount} un-itemized boxes using estimated average (320 Br/box)
                        </span>
                      </label>
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>

        </div>
      </div>

      {/* ========================================================================= */}
      {/* 2. CASH DEDUCTIONS & ADDITIONS */}
      {/* ========================================================================= */}
      <div className="space-y-4">
        <div className="flex items-center gap-2.5">
          <span className="w-7 h-7 bg-[#0B1D2C] text-white rounded-full flex items-center justify-center font-black text-xs">
            2
          </span>
          <h2 className="text-lg font-black tracking-tight text-[#0B1D2C]">
            Cash Deductions &amp; Additions
          </h2>
        </div>

        {/* 4 Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          
          {/* CARD 1: 1. Digital Transfers */}
          <div
            onClick={() => setIsTransferModalOpen(true)}
            className="bg-white rounded-3xl p-6 border border-[#0B1D2C]/15 shadow-xs hover:border-[#0B1D2C] transition cursor-pointer space-y-4 group"
          >
            <div className="flex items-start justify-between">
              <div>
                <h3 className="text-sm font-black text-[#0B1D2C] flex items-center gap-1.5">
                  <Smartphone className="w-4 h-4 text-cyan-600" /> 1. Digital Transfers
                </h3>
                <p className="text-[11px] text-[#0B1D2C]/60 mt-0.5">
                  Telebirr / CBE — Tap to calculate transfers.
                </p>
              </div>
              <div className="p-2 rounded-xl bg-[#f7f5f0] text-[#0B1D2C] group-hover:bg-[#0B1D2C] group-hover:text-white transition">
                <Calculator className="w-4 h-4" />
              </div>
            </div>

            <div>
              <span className="text-[10px] font-black uppercase text-[#0B1D2C]/50 tracking-wider block">
                TOTAL AMOUNT
              </span>
              <p className="text-2xl font-black text-[#0B1D2C]">
                Br {digitalTransfersTotal.toLocaleString('en-US', { minimumFractionDigits: 2 })}
              </p>
              <span className="text-[10px] text-cyan-700 font-bold">
                {transfers.filter(t => t.amount > 0).length} transfer records logged (Tap to edit)
              </span>
            </div>
          </div>

          {/* CARD 2: 2. Daily Cooking Expenses */}
          <div
            onClick={() => setIsExpenseModalOpen(true)}
            className="bg-white rounded-3xl p-6 border border-[#0B1D2C]/15 shadow-xs hover:border-[#0B1D2C] transition cursor-pointer space-y-4 group"
          >
            <div className="flex items-start justify-between">
              <div>
                <h3 className="text-sm font-black text-[#0B1D2C] flex items-center gap-1.5">
                  <Receipt className="w-4 h-4 text-red-600" /> 2. Daily Cooking Expenses
                </h3>
                <p className="text-[11px] text-[#0B1D2C]/60 mt-0.5">
                  Tap to calculate total spent on ingredients.
                </p>
              </div>
              <div className="p-2 rounded-xl bg-[#f7f5f0] text-[#0B1D2C] group-hover:bg-[#0B1D2C] group-hover:text-white transition">
                <Receipt className="w-4 h-4" />
              </div>
            </div>

            <div>
              <span className="text-[10px] font-black uppercase text-[#0B1D2C]/50 tracking-wider block">
                TOTAL AMOUNT
              </span>
              <p className="text-2xl font-black text-red-600">
                Br {dailyExpensesTotal.toLocaleString('en-US', { minimumFractionDigits: 2 })}
              </p>
              <span className="text-[10px] text-red-700 font-bold">
                {expenses.filter(e => e.amount > 0).length} expenses logged (Tap to edit)
              </span>
            </div>
          </div>

          {/* CARD 3: 3. New Unpaid Pending Credit */}
          <div className="bg-white rounded-3xl p-6 border border-[#0B1D2C]/15 shadow-xs space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-black text-[#0B1D2C] flex items-center gap-1.5">
                  <Clock className="w-4 h-4 text-amber-600" /> 3. New Unpaid Pending Credit
                </h3>
                <p className="text-[10px] text-[#0B1D2C]/60">
                  Cups &amp; boxes given on credit to unpaid customers.
                </p>
              </div>
              <span className="px-2.5 py-0.5 bg-rose-100 text-rose-800 rounded-full text-[10px] font-black uppercase">
                - DEDUCTED
              </span>
            </div>

            <div>
              <label className="block text-[10px] font-black uppercase text-[#0B1D2C]/60 mb-1">
                CUSTOMER NAME
              </label>
              <input
                type="text"
                value={newPendingCustomerName}
                onChange={e => setNewPendingCustomerName(e.target.value)}
                placeholder="e.g. Abebe"
                className="w-full bg-[#f7f5f0] border border-[#0B1D2C]/20 rounded-2xl px-3.5 py-2 text-xs font-bold text-[#0B1D2C] outline-none focus:border-[#0B1D2C]"
              />
            </div>

            {/* Stepper items for new credit */}
            <div className="bg-[#f7f5f0] rounded-2xl p-3 border border-[#0B1D2C]/10 space-y-2 max-h-48 overflow-y-auto">
              <div className="flex items-center justify-between text-xs">
                <span className="font-bold text-[#0B1D2C]">Juice &amp; Smoothie Cups ({juiceUnitPrice} Br)</span>
                <div className="flex items-center gap-1 bg-white border border-[#0B1D2C]/20 rounded-full p-1">
                  <button
                    type="button"
                    onClick={() => setNewPendingJuiceCups(prev => Math.max(0, prev - 1))}
                    className="w-5 h-5 rounded-full bg-[#f7f5f0] flex items-center justify-center font-bold text-xs"
                  >
                    -
                  </button>
                  <span className="w-6 text-center font-black text-xs">{newPendingJuiceCups}</span>
                  <button
                    type="button"
                    onClick={() => setNewPendingJuiceCups(prev => prev + 1)}
                    className="w-5 h-5 rounded-full bg-[#0B1D2C] text-white flex items-center justify-center font-bold text-xs"
                  >
                    +
                  </button>
                </div>
              </div>

              {foodProducts.slice(0, 3).map(dish => (
                <div key={dish.id} className="flex items-center justify-between text-xs">
                  <span className="font-bold text-[#0B1D2C] truncate pr-2">{dish.name} ({dish.price} Br)</span>
                  <div className="flex items-center gap-1 bg-white border border-[#0B1D2C]/20 rounded-full p-1 shrink-0">
                    <button
                      type="button"
                      onClick={() => setNewPendingFoodItems(prev => ({
                        ...prev,
                        [dish.name]: Math.max(0, (prev[dish.name] || 0) - 1)
                      }))}
                      className="w-5 h-5 rounded-full bg-[#f7f5f0] flex items-center justify-center font-bold text-xs"
                    >
                      -
                    </button>
                    <span className="w-6 text-center font-black text-xs">{newPendingFoodItems[dish.name] || 0}</span>
                    <button
                      type="button"
                      onClick={() => setNewPendingFoodItems(prev => ({
                        ...prev,
                        [dish.name]: (prev[dish.name] || 0) + 1
                      }))}
                      className="w-5 h-5 rounded-full bg-[#0B1D2C] text-white flex items-center justify-center font-bold text-xs"
                    >
                      +
                    </button>
                  </div>
                </div>
              ))}
            </div>

            <div className="pt-2 border-t border-[#0B1D2C]/10 flex items-center justify-between text-xs font-black">
              <span className="text-[#0B1D2C]/70">Deduction Total:</span>
              <span className="text-base text-rose-600">Br {newPendingCreditTotal.toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
            </div>
          </div>

          {/* CARD 4: 4. Recovered Past Pending Debts */}
          <div className="bg-white rounded-3xl p-6 border border-[#0B1D2C]/15 shadow-xs space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-sm font-black text-[#0B1D2C] flex items-center gap-1.5">
                  <CheckCircle2 className="w-4 h-4 text-emerald-600" /> 4. Recovered Past Pending Debts
                </h3>
                <p className="text-[10px] text-[#0B1D2C]/60">
                  Past pending debts paid off in cash during this shift.
                </p>
              </div>
              <span className="px-2.5 py-0.5 bg-emerald-100 text-emerald-800 rounded-full text-[10px] font-black uppercase">
                + ADDED CASH
              </span>
            </div>

            {/* List of existing unpaid debtors */}
            <div className="bg-[#f7f5f0] rounded-2xl p-3 border border-[#0B1D2C]/10 space-y-2.5 max-h-56 overflow-y-auto">
              <div className="flex items-center justify-between text-[11px] font-black text-[#0B1D2C]">
                <span>Unpaid Customer Debts (Full or Partial Settlement):</span>
                <span className="px-2 py-0.5 bg-white rounded-md border text-[10px]">{activeUnpaidDebts.length} Unpaid Total</span>
              </div>

              {activeUnpaidDebts.map(d => {
                const isFull = !!selectedDebtsFull[d.id];
                const partialCups = selectedDebtsPartialCups[d.id] || 0;
                return (
                  <div key={d.id} className="p-2.5 bg-white rounded-xl border border-[#0B1D2C]/10 space-y-1.5">
                    <div className="flex items-center justify-between text-xs">
                      <div>
                        <strong className="text-[#0B1D2C] block font-extrabold">{d.customerName}</strong>
                        <span className="text-[10px] text-[#0B1D2C]/60">{d.note || 'Unpaid Juice'} • {d.cupCount} Cups</span>
                      </div>
                      <span className="font-black text-xs text-[#0B1D2C]">Br {d.amount.toLocaleString()}</span>
                    </div>
                    <div className="flex items-center justify-between pt-1 border-t border-gray-100 text-xs">
                      <label className="flex items-center gap-1.5 cursor-pointer text-[11px] font-bold text-emerald-800">
                        <input
                          type="checkbox"
                          checked={isFull}
                          onChange={e => setSelectedDebtsFull(prev => ({ ...prev, [d.id]: e.target.checked }))}
                          className="rounded text-emerald-600"
                        />
                        Full Settlement (Br {d.amount})
                      </label>
                      {!isFull && (
                        <div className="flex items-center gap-1 bg-[#f7f5f0] border rounded-full px-2 py-0.5 text-[10px] font-bold">
                          <span>Paid Cups:</span>
                          <button
                            type="button"
                            onClick={() => setSelectedDebtsPartialCups(prev => ({ ...prev, [d.id]: Math.max(0, (prev[d.id] || 0) - 1) }))}
                            className="w-4 h-4 bg-white rounded-full flex items-center justify-center font-bold"
                          >
                            -
                          </button>
                          <span className="w-4 text-center font-black">{partialCups}</span>
                          <button
                            type="button"
                            onClick={() => setSelectedDebtsPartialCups(prev => ({ ...prev, [d.id]: Math.min(d.cupCount, (prev[d.id] || 0) + 1) }))}
                            className="w-4 h-4 bg-[#0B1D2C] text-white rounded-full flex items-center justify-center font-bold"
                          >
                            +
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            <div className="pt-2 border-t border-[#0B1D2C]/10 flex items-center justify-between text-xs font-black">
              <span className="text-[#0B1D2C]/70">Total Recovered Cash:</span>
              <span className="text-base text-emerald-700 font-extrabold">+Br {recoveredDebtsTotal.toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
            </div>
          </div>

        </div>

        {/* CARD 5: 5. Delivery Rider Credit Orders */}
        <div className="bg-white rounded-3xl p-6 border border-[#0B1D2C]/15 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-sm font-black text-[#0B1D2C] flex items-center gap-1.5">
                <Truck className="w-4 h-4 text-purple-600" /> 5. Delivery Rider Credit Orders
              </h3>
              <p className="text-[11px] text-[#0B1D2C]/60 mt-0.5">
                Delivered via BeU / Deliver Addis / Feres riders on weekly account.
              </p>
            </div>
            <span className="px-2.5 py-0.5 bg-purple-100 text-purple-800 rounded-full text-[10px] font-black uppercase">
              - DEDUCTED
            </span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-[10px] font-black uppercase text-[#0B1D2C]/60 mb-1">
                CUPS
              </label>
              <input
                type="number"
                value={deliveryCups}
                onChange={e => setDeliveryCups(Math.max(0, Number(e.target.value) || 0))}
                className="w-full bg-[#f7f5f0] border border-[#0B1D2C]/20 rounded-full py-2 px-3 text-center font-black text-xs outline-none"
              />
            </div>

            <div>
              <label className="block text-[10px] font-black uppercase text-[#0B1D2C]/60 mb-1">
                BOXES
              </label>
              <input
                type="number"
                value={deliveryBoxes}
                onChange={e => setDeliveryBoxes(Math.max(0, Number(e.target.value) || 0))}
                className="w-full bg-[#f7f5f0] border border-[#0B1D2C]/20 rounded-full py-2 px-3 text-center font-black text-xs outline-none"
              />
            </div>

            <div>
              <label className="block text-[10px] font-black uppercase text-[#0B1D2C]/60 mb-1">
                RIDER / COMPANY
              </label>
              <input
                type="text"
                value={deliveryPartnerName}
                onChange={e => setDeliveryPartnerName(e.target.value)}
                className="w-full bg-[#f7f5f0] border border-[#0B1D2C]/20 rounded-full py-2 px-4 font-bold text-xs outline-none"
              />
            </div>
          </div>

          <div className="pt-2 border-t border-[#0B1D2C]/10 flex items-center justify-between text-xs font-black">
            <span className="text-[#0B1D2C]/70">Deduction Total:</span>
            <span className="text-base text-purple-700">Br {deliveryDeductionTotal.toLocaleString('en-US', { minimumFractionDigits: 2 })}</span>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 3. PHYSICAL CASH HANDOVER GRAND CARD */}
      {/* ========================================================================= */}
      <div className="bg-[#0B1D2C] text-white rounded-3xl p-6 sm:p-8 shadow-2xl border border-[#0B1D2C]/40 space-y-6">
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="space-y-1">
            <div className="flex items-center gap-2 text-white/70 text-xs font-extrabold uppercase tracking-wider">
              <ShieldCheck className="w-4 h-4 text-emerald-400" /> PHYSICAL CASH HANDOVER
            </div>
            <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
              Net Cash Due to Owner
            </h2>
            <p className="text-xs text-white/70">
              Exact cash worker must hand over at end of shift
            </p>
          </div>

          <div className="text-left md:text-right">
            <p className="text-4xl sm:text-5xl font-black text-white tracking-tight">
              Br {netCashDueToOwner.toLocaleString('en-US', { minimumFractionDigits: 2 })}
            </p>
          </div>
        </div>

        {/* Math formula bar */}
        <div className="bg-white/5 p-3.5 rounded-2xl border border-white/10 flex flex-wrap items-center gap-x-4 gap-y-2 text-xs font-bold text-white/80">
          <span>Gross: <strong className="text-white">Br {grossRevenue.toLocaleString()}</strong></span>
          <span>- Digital: <strong className="text-cyan-400">Br {digitalTransfersTotal.toLocaleString()}</strong></span>
          <span>- Exp: <strong className="text-red-400">Br {dailyExpensesTotal.toLocaleString()}</strong></span>
          <span>- Pend: <strong className="text-rose-400">Br {newPendingCreditTotal.toLocaleString()}</strong></span>
          <span>+ Rec: <strong className="text-emerald-400">Br {recoveredDebtsTotal.toLocaleString()}</strong></span>
          <span>- Del: <strong className="text-purple-400">Br {deliveryDeductionTotal.toLocaleString()}</strong></span>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 4. SHIFT NOTES & SUBMIT ACTION */}
      {/* ========================================================================= */}
      <div className="bg-white rounded-3xl p-6 border border-[#0B1D2C]/15 shadow-xs space-y-4">
        <div>
          <label className="block text-xs font-black uppercase text-[#0B1D2C]/70 mb-2">
            SHIFT NOTES &amp; LOG COMMENTS
          </label>
          <textarea
            value={shiftNotes}
            onChange={e => setShiftNotes(e.target.value)}
            rows={3}
            placeholder="Record any stock handover observations or notes..."
            className="w-full bg-[#f7f5f0] border border-[#0B1D2C]/20 rounded-2xl p-4 text-xs font-medium text-[#0B1D2C] outline-none focus:border-[#0B1D2C] resize-none"
          />
        </div>

        <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-2">
          <div className="text-xs text-[#0B1D2C]/60">
            Shift: <strong>{selectedDate} ({activeShift === 'day' ? 'Day' : 'Night'})</strong> • Worker: <strong>{currentWorkerName}</strong>
          </div>
          <button
            type="button"
            onClick={() => {
              setPinInput('');
              setPinError(null);
              setIsPinModalOpen(true);
            }}
            className="w-full sm:w-auto px-8 py-3.5 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white font-black text-sm rounded-2xl shadow-xl flex items-center justify-center gap-2 transition active:scale-95 cursor-pointer"
          >
            <Lock className="w-4 h-4" /> 🔒 በፒን አረጋግጥ እና ዝጋ (Save &amp; Close Shift)
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* DIGITAL TRANSFERS MODAL */}
      {/* ========================================================================= */}
      {isTransferModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 max-w-lg w-full shadow-2xl border border-[#0B1D2C]/20 space-y-4 max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <h3 className="text-base font-black text-[#0B1D2C] flex items-center gap-2">
                <Smartphone className="w-5 h-5 text-cyan-600" /> Digital Transfers (Telebirr / CBE)
              </h3>
              <button
                onClick={() => setIsTransferModalOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-black"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-2.5">
              {transfers.map((tf, idx) => (
                <div key={tf.id} className="p-3 bg-[#f7f5f0] rounded-2xl border border-[#0B1D2C]/10 flex items-center gap-2">
                  <span className="text-xs font-black text-[#0B1D2C]/50 w-5">#{idx + 1}</span>
                  <input
                    type="text"
                    value={tf.senderName}
                    onChange={e => handleUpdateTransfer(tf.id, 'senderName', e.target.value)}
                    placeholder="Sender name"
                    className="flex-1 bg-white border border-gray-200 rounded-xl px-2.5 py-1.5 text-xs font-bold outline-none"
                  />
                  <input
                    type="number"
                    value={tf.amount || ''}
                    onChange={e => handleUpdateTransfer(tf.id, 'amount', e.target.value)}
                    placeholder="Amount Br"
                    className="w-24 bg-white border border-gray-200 rounded-xl px-2.5 py-1.5 text-xs font-black text-right outline-none"
                  />
                  <input
                    type="text"
                    value={tf.note}
                    onChange={e => handleUpdateTransfer(tf.id, 'note', e.target.value)}
                    placeholder="Telebirr / CBE"
                    className="w-24 bg-white border border-gray-200 rounded-xl px-2 py-1.5 text-xs outline-none"
                  />
                  <button
                    type="button"
                    onClick={() => handleRemoveTransfer(tf.id)}
                    className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </div>

            <button
              type="button"
              onClick={handleAddTransfer}
              className="w-full py-2 bg-[#f7f5f0] hover:bg-gray-200 border border-dashed border-[#0B1D2C]/20 rounded-xl text-xs font-bold text-[#0B1D2C] flex items-center justify-center gap-1.5"
            >
              <Plus className="w-3.5 h-3.5" /> Add Transfer Row
            </button>

            <div className="pt-3 border-t flex items-center justify-between">
              <span className="text-xs font-black text-[#0B1D2C]">
                Total: Br {digitalTransfersTotal.toLocaleString('en-US', { minimumFractionDigits: 2 })}
              </span>
              <button
                type="button"
                onClick={() => setIsTransferModalOpen(false)}
                className="px-5 py-2 bg-[#0B1D2C] text-white font-bold text-xs rounded-xl"
              >
                Done (አጠናቅቅ)
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* DAILY EXPENSES MODAL */}
      {/* ========================================================================= */}
      {isExpenseModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 max-w-lg w-full shadow-2xl border border-[#0B1D2C]/20 space-y-4 max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <h3 className="text-base font-black text-[#0B1D2C] flex items-center gap-2">
                <Receipt className="w-5 h-5 text-red-600" /> Daily Cooking &amp; Shift Expenses
              </h3>
              <button
                onClick={() => setIsExpenseModalOpen(false)}
                className="p-1 rounded-lg text-gray-400 hover:text-black"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Quick Add Preset Buttons */}
            <div className="flex flex-wrap gap-2 text-xs">
              <span className="text-[10px] font-black text-[#0B1D2C]/60 w-full">Quick Add:</span>
              {[
                { name: '🍋 2kg ሎሚ (Lemon)', amt: 120 },
                { name: '🧊 በረዶ (Ice)', amt: 100 },
                { name: '🧹 ጽዳት (Cleaning)', amt: 80 },
                { name: '🥛 ወተት (Milk)', amt: 250 },
              ].map(q => (
                <button
                  key={q.name}
                  type="button"
                  onClick={() => setExpenses(prev => [...prev, {
                    id: `exp-${Date.now()}`,
                    shiftId: 'shift',
                    category: 'Kitchen supplies',
                    description: q.name,
                    amount: q.amt,
                    loggedAt: new Date().toISOString()
                  }])}
                  className="px-2.5 py-1 bg-[#f7f5f0] hover:bg-gray-200 rounded-lg font-bold text-[11px]"
                >
                  +{q.name} ({q.amt} Br)
                </button>
              ))}
            </div>

            <div className="space-y-2.5">
              {expenses.map((exp, idx) => (
                <div key={exp.id} className="p-3 bg-[#f7f5f0] rounded-2xl border border-[#0B1D2C]/10 flex items-center gap-2">
                  <span className="text-xs font-black text-[#0B1D2C]/50 w-5">#{idx + 1}</span>
                  <input
                    type="text"
                    value={exp.description}
                    onChange={e => handleUpdateExpense(exp.id, 'description', e.target.value)}
                    placeholder="Expense item (e.g. ሎሚ / Lemons)"
                    className="flex-1 bg-white border border-gray-200 rounded-xl px-2.5 py-1.5 text-xs font-bold outline-none"
                  />
                  <input
                    type="number"
                    value={exp.amount || ''}
                    onChange={e => handleUpdateExpense(exp.id, 'amount', e.target.value)}
                    placeholder="Amount Br"
                    className="w-24 bg-white border border-gray-200 rounded-xl px-2.5 py-1.5 text-xs font-black text-right outline-none text-red-600"
                  />
                  <button
                    type="button"
                    onClick={() => handleRemoveExpense(exp.id)}
                    className="p-1.5 text-red-500 hover:bg-red-50 rounded-lg"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              ))}
            </div>

            <button
              type="button"
              onClick={handleAddExpense}
              className="w-full py-2 bg-[#f7f5f0] hover:bg-gray-200 border border-dashed border-[#0B1D2C]/20 rounded-xl text-xs font-bold text-[#0B1D2C] flex items-center justify-center gap-1.5"
            >
              <Plus className="w-3.5 h-3.5" /> Add Expense Row
            </button>

            <div className="pt-3 border-t flex items-center justify-between">
              <span className="text-xs font-black text-red-600">
                Total: Br {dailyExpensesTotal.toLocaleString('en-US', { minimumFractionDigits: 2 })}
              </span>
              <button
                type="button"
                onClick={() => setIsExpenseModalOpen(false)}
                className="px-5 py-2 bg-[#0B1D2C] text-white font-bold text-xs rounded-xl"
              >
                Done (አጠናቅቅ)
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 4-DIGIT PIN CONFIRMATION MODAL */}
      {/* ========================================================================= */}
      {isPinModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 sm:p-8 max-w-sm w-full shadow-2xl border-2 border-[#0B1D2C] space-y-5 text-center">
            <div className="w-12 h-12 bg-amber-100 text-amber-700 rounded-2xl flex items-center justify-center mx-auto">
              <Lock className="w-6 h-6" />
            </div>

            <div>
              <h3 className="text-base font-black text-[#0B1D2C]">
                Enter 4-Digit Shift PIN
              </h3>
              <p className="text-xs text-[#0B1D2C]/60 mt-1">
                የሺፍት ሪፖርቱን አጽድቀው ለመዝጋት እባክዎ ፒን ቁጥርዎን ያስገቡ (Default: <code>1234</code>)
              </p>
            </div>

            <div className="space-y-3">
              <input
                type="password"
                maxLength={4}
                value={pinInput}
                onChange={e => setPinInput(e.target.value)}
                placeholder="••••"
                autoFocus
                className="w-36 bg-[#f7f5f0] border-2 border-[#0B1D2C] rounded-2xl py-3 text-center text-2xl font-black tracking-widest outline-none mx-auto"
              />

              {pinError && (
                <p className="text-xs text-rose-600 font-bold">{pinError}</p>
              )}
            </div>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                disabled={isSubmitting}
                onClick={handleConfirmCloseShift}
                className="flex-1 py-3 bg-[#0B1D2C] hover:bg-[#162e44] text-white rounded-xl font-black text-xs shadow-lg transition active:scale-95"
              >
                {isSubmitting ? 'በማስቀመጥ ላይ...' : 'አረጋግጥና ዝጋ (Confirm)'}
              </button>
              <button
                type="button"
                onClick={() => setIsPinModalOpen(false)}
                className="px-4 py-3 bg-gray-200 text-[#0B1D2C] rounded-xl font-bold text-xs"
              >
                ሰርዝ
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}
