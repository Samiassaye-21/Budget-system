'use client';

import React, { useState, useMemo, useEffect } from 'react';
import {
  X, Check, ArrowRight, ArrowLeft, Plus, Trash2, DollarSign, Wallet, Smartphone,
  CreditCard, Truck, AlertCircle, Lock, Receipt, ShieldCheck, Utensils,
  Calendar, Sun, Moon, Sparkles, RefreshCw, AlertTriangle, Info, CheckCircle2,
  FileSpreadsheet, User, Coffee, HelpCircle
} from 'lucide-react';
import {
  Product, CustomerDebt, ShiftType, KitchenTicket, ManualShiftReconciliation,
  FoodBoxEntry, FoodSoldEntry, JuiceEntry, TransferRecord, ShiftExpense,
  ManualPendingPayment, ManualRecoveredPayment
} from '../types/pos';
import { dataService } from '../lib/dataService';

interface ManualReconciliationWizardProps {
  products: Product[];
  initialDebts: CustomerDebt[];
  onClose: () => void;
  onComplete: (recon: ManualShiftReconciliation) => void;
}

export function ManualReconciliationWizard({
  products,
  initialDebts,
  onClose,
  onComplete,
}: ManualReconciliationWizardProps) {
  const [step, setStep] = useState<number>(1);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);

  // STEP 1: Shift Identity
  const [shiftDate, setShiftDate] = useState<string>(() => new Date().toISOString().slice(0, 10));
  const [shiftType, setShiftType] = useState<ShiftType>('day');
  const [cashierName, setCashierName] = useState<string>('ሳራ መኮንን (Sara Mekonnen)');
  const [kitchenAlertDismissed, setKitchenAlertDismissed] = useState<boolean>(false);

  // STEP 2: Juice Inventory (Cups)
  const [openingCups, setOpeningCups] = useState<string>('120');
  const [addedCups, setAddedCups] = useState<string>('0');
  const [leftoverCups, setLeftoverCups] = useState<string>('');

  const numOpeningCups = Number(openingCups) || 0;
  const numAddedCups = Number(addedCups) || 0;
  const numLeftoverCups = leftoverCups === '' ? null : Number(leftoverCups);
  const calculatedCupsSold = numLeftoverCups !== null ? Math.max(0, (numOpeningCups + numAddedCups) - numLeftoverCups) : 0;

  // Catalog products
  const foodProducts = useMemo(() => products.filter(p => p.category === 'Food'), [products]);
  const juiceProducts = useMemo(() => products.filter(p => p.category === 'Juice'), [products]);

  // STEP 3: Juice Breakdown by Type
  const [juiceSoldMap, setJuiceSoldMap] = useState<{ [name: string]: number }>({});
  const totalJuiceSoldByType = useMemo(() => {
    return Object.values(juiceSoldMap).reduce((a, b) => a + (Number(b) || 0), 0);
  }, [juiceSoldMap]);

  // Kitchen Auto-Lookup for this Date + Shift
  const kitchenTicketsForShift = useMemo(() => {
    return dataService.getKitchenTicketsByDateAndShift(shiftDate, shiftType);
  }, [shiftDate, shiftType]);

  const kitchenDataFound = kitchenTicketsForShift.length > 0;

  // Kitchen cooked summary by food item name
  const kitchenFoodSummary = useMemo(() => {
    const map: { [name: string]: number } = {};
    kitchenTicketsForShift.forEach(t => {
      t.items.forEach(item => {
        map[item.name] = (map[item.name] || 0) + item.quantity;
      });
    });
    return map;
  }, [kitchenTicketsForShift]);

  const totalKitchenCookedCount = useMemo(() => {
    return Object.values(kitchenFoodSummary).reduce((a, b) => a + b, 0);
  }, [kitchenFoodSummary]);

  // STEP 4: Food Box Inventory state (Opening, Leftover per food item)
  const [foodBoxOpenings, setFoodBoxOpenings] = useState<{ [name: string]: number }>({});
  const [foodBoxLeftovers, setFoodBoxLeftovers] = useState<{ [name: string]: number }>({});

  // STEP 5: Food Sold (Waiter) state
  const [foodSoldMap, setFoodSoldMap] = useState<{ [name: string]: number }>({});
  const totalWaiterFoodSold = useMemo(() => {
    return Object.values(foodSoldMap).reduce((a, b) => a + (Number(b) || 0), 0);
  }, [foodSoldMap]);

  // STEP 6: Sales Breakdown
  const [cashSales, setCashSales] = useState<string>('0');
  const [transferSales, setTransferSales] = useState<string>('0');
  const [creditSales, setCreditSales] = useState<string>('0');
  const [deliverySales, setDeliverySales] = useState<string>('0');
  const [tipSales, setTipSales] = useState<string>('0');
  const [totalOrdersCount, setTotalOrdersCount] = useState<string>('0');

  const numCash = Number(cashSales) || 0;
  const numTransfer = Number(transferSales) || 0;
  const numCredit = Number(creditSales) || 0;
  const numDelivery = Number(deliverySales) || 0;
  const numTip = Number(tipSales) || 0;
  const grossRevenue = numCash + numTransfer + numCredit + numDelivery + numTip;

  // STEP 7: Transfer Records
  const [transfers, setTransfers] = useState<TransferRecord[]>([
    { id: 'tf-1', senderName: '', amount: 0, note: 'Telebirr' }
  ]);
  const totalTransfersLogged = useMemo(() => {
    return transfers.reduce((sum, t) => sum + (Number(t.amount) || 0), 0);
  }, [transfers]);

  // STEP 8: Expenses
  const [expenses, setExpenses] = useState<ShiftExpense[]>([
    { id: 'exp-1', shiftId: 'manual', category: 'Kitchen supplies', description: '', amount: 0, loggedAt: new Date().toISOString() }
  ]);
  const totalExpenses = useMemo(() => {
    return expenses.reduce((sum, e) => sum + (Number(e.amount) || 0), 0);
  }, [expenses]);

  // STEP 9: Pending Payments (New Debts)
  const [pendingPayments, setPendingPayments] = useState<ManualPendingPayment[]>([]);
  const totalNewDebts = useMemo(() => {
    return pendingPayments.reduce((sum, p) => sum + (Number(p.amount) || 0), 0);
  }, [pendingPayments]);

  // STEP 10: Recovered Payments
  const [selectedDebts, setSelectedDebts] = useState<{ [debtId: string]: boolean }>({});
  const [customRecoveries, setCustomRecoveries] = useState<ManualRecoveredPayment[]>([]);

  const totalRecoveredDebts = useMemo(() => {
    let sum = 0;
    initialDebts.forEach(d => {
      if (selectedDebts[d.id]) {
        sum += d.amount;
      }
    });
    customRecoveries.forEach(cr => {
      sum += Number(cr.amount) || 0;
    });
    return sum;
  }, [initialDebts, selectedDebts, customRecoveries]);

  // STEP 11: Final Net Cash & Notes
  const [shiftNotes, setShiftNotes] = useState<string>('');

  // FORMULA: Net Cash to Owner = Cash Sales + Recovered Debts - Total Expenses
  const netCashToOwner = numCash + totalRecoveredDebts - totalExpenses;

  // Auto-reset alert dismissed state when date/shift changes
  useEffect(() => {
    setKitchenAlertDismissed(false);
  }, [shiftDate, shiftType]);

  // Handlers for dynamic lists
  const handleAddTransfer = () => {
    setTransfers(prev => [
      ...prev,
      { id: `tf-${Date.now()}`, senderName: '', amount: 0, note: 'Telebirr' }
    ]);
  };

  const handleRemoveTransfer = (id: string) => {
    setTransfers(prev => prev.filter(t => t.id !== id));
  };

  const handleUpdateTransfer = (id: string, field: keyof TransferRecord, value: any) => {
    setTransfers(prev =>
      prev.map(t => (t.id === id ? { ...t, [field]: field === 'amount' ? Number(value) || 0 : value } : t))
    );
  };

  const handleAddExpense = () => {
    setExpenses(prev => [
      ...prev,
      { id: `exp-${Date.now()}`, shiftId: 'manual', category: 'Kitchen supplies', description: '', amount: 0, loggedAt: new Date().toISOString() }
    ]);
  };

  const handleRemoveExpense = (id: string) => {
    setExpenses(prev => prev.filter(e => e.id !== id));
  };

  const handleUpdateExpense = (id: string, field: keyof ShiftExpense, value: any) => {
    setExpenses(prev =>
      prev.map(e => (e.id === id ? { ...e, [field]: field === 'amount' ? Number(value) || 0 : value } : e))
    );
  };

  const handleAddPendingPayment = () => {
    setPendingPayments(prev => [
      ...prev,
      { id: `deb-new-${Date.now()}`, customerName: '', amount: 0, note: '' }
    ]);
  };

  const handleRemovePendingPayment = (id: string) => {
    setPendingPayments(prev => prev.filter(p => p.id !== id));
  };

  const handleUpdatePendingPayment = (id: string, field: keyof ManualPendingPayment, value: any) => {
    setPendingPayments(prev =>
      prev.map(p => (p.id === id ? { ...p, [field]: field === 'amount' ? Number(value) || 0 : value } : p))
    );
  };

  const handleAddCustomRecovery = () => {
    setCustomRecoveries(prev => [
      ...prev,
      { debtId: `rec-${Date.now()}`, customerName: '', amount: 0 }
    ]);
  };

  const handleRemoveCustomRecovery = (debtId: string) => {
    setCustomRecoveries(prev => prev.filter(r => r.debtId !== debtId));
  };

  const handleUpdateCustomRecovery = (debtId: string, field: keyof ManualRecoveredPayment, value: any) => {
    setCustomRecoveries(prev =>
      prev.map(r => (r.debtId === debtId ? { ...r, [field]: field === 'amount' ? Number(value) || 0 : value } : r))
    );
  };

  // Submit Handler
  const handleSubmit = async () => {
    setIsSubmitting(true);
    try {
      // Build food box entries
      const foodBoxInventory: FoodBoxEntry[] = foodProducts.map(p => {
        const opening = foodBoxOpenings[p.name] || 0;
        const leftover = foodBoxLeftovers[p.name] || 0;
        const consumed = Math.max(0, opening - leftover);
        const kitchenCooked = kitchenFoodSummary[p.name] || 0;
        return {
          name: p.name,
          emoji: p.emoji,
          opening,
          leftover,
          consumed,
          kitchenCooked
        };
      });

      // Build food sold entries
      const foodSoldBreakdown: FoodSoldEntry[] = foodProducts.map(p => {
        const sold = foodSoldMap[p.name] || 0;
        const kitchenCooked = kitchenFoodSummary[p.name] || 0;
        return {
          name: p.name,
          emoji: p.emoji,
          sold,
          kitchenCooked,
          variance: sold - kitchenCooked
        };
      });

      // Build juice breakdown
      const juiceBreakdown: JuiceEntry[] = juiceProducts.map(p => ({
        name: p.name,
        emoji: p.emoji,
        sold: juiceSoldMap[p.name] || 0
      }));

      // Build recovered payments list
      const recoveredPaymentsList: ManualRecoveredPayment[] = [
        ...initialDebts
          .filter(d => selectedDebts[d.id])
          .map(d => ({ debtId: d.id, customerName: d.customerName, amount: d.amount })),
        ...customRecoveries.filter(r => r.customerName && r.amount > 0)
      ];

      const manualRecon: ManualShiftReconciliation = {
        id: `recon-manual-${Date.now()}`,
        shiftId: `shift-manual-${shiftDate}-${shiftType}`,
        shiftType,
        cashierName,
        entryMode: 'manual',
        shiftDate,
        grossRevenue,
        cashSales: numCash,
        transferSales: numTransfer,
        creditSales: numCredit,
        deliverySales: numDelivery,
        tipSales: numTip,
        totalOrdersCount: Number(totalOrdersCount) || 0,
        openingCups: numOpeningCups,
        addedCups: numAddedCups,
        leftoverCups: numLeftoverCups ?? 0,
        calculatedCupsSold,
        tabletCupsSold: calculatedCupsSold,
        cupsVariance: 0,
        totalKitchenFoodCooked: totalKitchenCookedCount,
        totalWaiterFoodSold,
        foodVariance: totalWaiterFoodSold - totalKitchenCookedCount,
        foodItemsReconciliation: foodSoldBreakdown.map(f => ({
          id: f.name,
          name: f.name,
          emoji: f.emoji,
          kitchenCookedCount: f.kitchenCooked,
          waiterSoldCount: f.sold,
          variance: f.variance
        })),
        totalExpenses,
        expenses: expenses.filter(e => e.amount > 0),
        totalRecoveredCups: Math.round(totalRecoveredDebts / 170) || 0,
        totalRecoveredDebts,
        recoveredDebts: initialDebts.filter(d => selectedDebts[d.id]),
        netCashToOwner,
        shiftNotes,
        closedAt: new Date().toISOString(),
        juiceBreakdown,
        foodBoxInventory,
        foodSoldBreakdown,
        transferRecords: transfers.filter(t => t.amount > 0),
        pendingPayments: pendingPayments.filter(p => p.amount > 0),
        recoveredPayments: recoveredPaymentsList,
        kitchenDataFound
      };

      await dataService.saveManualReconciliation(manualRecon);
      onComplete(manualRecon);
    } catch (err) {
      console.error('Error submitting manual reconciliation:', err);
      alert('Error saving reconciliation. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const stepTitles = [
    '1. Shift & Date',
    '2. Juice Cup Count',
    '3. Juice Sold by Type',
    '4. Food Box Count',
    '5. Waiter Food Sold',
    '6. Sales Breakdown',
    '7. Bank Transfers',
    '8. Shift Expenses',
    '9. Pending Debts',
    '10. Recovered Debts',
    '11. Summary & Handover'
  ];

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-3 md:p-6 overflow-y-auto animate-fadeIn">
      <div className="bg-[#121826] text-white w-full max-w-4xl rounded-2xl border border-gray-800 shadow-2xl flex flex-col max-h-[92vh] overflow-hidden">
        
        {/* HEADER */}
        <div className="p-4 md:px-6 bg-[#1a2234] border-b border-gray-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="p-2.5 bg-amber-500/20 border border-amber-500/30 rounded-xl text-amber-400">
              <FileSpreadsheet className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="font-extrabold text-lg md:text-xl text-white tracking-wide">
                  Manual Shift Reconciliation
                </h2>
                <span className="px-2 py-0.5 text-[10px] font-bold uppercase rounded-full bg-purple-500/20 text-purple-300 border border-purple-500/30">
                  Admin Entry
                </span>
              </div>
              <p className="text-xs text-gray-400">
                1. ቆጠራ (Inventory) ➔ 2. ሽያጭና ገንዘብ (Sales &amp; Cash) • Maraki POS
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-xl text-gray-400 hover:text-white hover:bg-gray-800 transition"
            title="Cancel and close"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* PROGRESS BAR & STEP INDICATOR */}
        <div className="bg-[#151c2c] px-4 md:px-6 py-2.5 border-b border-gray-800/80 flex items-center justify-between">
          <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-1">
            {stepTitles.map((title, idx) => {
              const stepNum = idx + 1;
              const isCurrent = step === stepNum;
              const isPast = step > stepNum;
              return (
                <button
                  key={stepNum}
                  onClick={() => setStep(stepNum)}
                  className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
                    isCurrent
                      ? 'bg-amber-500 text-black shadow-md'
                      : isPast
                      ? 'bg-emerald-950/60 text-emerald-300 border border-emerald-800/40 hover:bg-emerald-900/40'
                      : 'bg-gray-800/50 text-gray-400 hover:text-gray-200'
                  }`}
                >
                  <span>{stepNum}</span>
                  <span className="hidden sm:inline">{title.split('.')[1]}</span>
                </button>
              );
            })}
          </div>
          <span className="text-xs text-gray-400 font-mono ml-3 shrink-0">
            {step} / 11
          </span>
        </div>

        {/* KITCHEN AUTO-CHECK BANNER (Always visible when relevant) */}
        {kitchenDataFound && !kitchenAlertDismissed && (
          <div className="bg-amber-950/60 border-b border-amber-500/30 px-4 md:px-6 py-3 flex items-center justify-between gap-3 text-amber-200 text-xs">
            <div className="flex items-center gap-2.5">
              <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0" />
              <span>
                <strong>Kitchen Records Detected!</strong> The kitchen logged <strong>{kitchenTicketsForShift.length} orders ({totalKitchenCookedCount} dishes)</strong> for <strong>{shiftDate} ({shiftType === 'day' ? 'Day Shift' : 'Night Shift'})</strong>. Cooked numbers are loaded into Steps 4 &amp; 5.
              </span>
            </div>
            <button
              onClick={() => setKitchenAlertDismissed(true)}
              className="text-amber-400 hover:text-amber-100 font-bold text-xs underline shrink-0"
            >
              Dismiss
            </button>
          </div>
        )}

        {!kitchenDataFound && (
          <div className="bg-blue-950/40 border-b border-blue-500/20 px-4 md:px-6 py-2 flex items-center gap-2 text-blue-300 text-xs">
            <Info className="w-4 h-4 text-blue-400 shrink-0" />
            <span>
              <strong>0 Kitchen Records:</strong> No kitchen tickets found for <strong>{shiftDate} ({shiftType === 'day' ? 'Day Shift' : 'Night Shift'})</strong>. You can enter all quantities manually.
            </span>
          </div>
        )}

        {/* BODY CONTENT - STEP PANELS */}
        <div className="flex-1 overflow-y-auto p-4 md:p-6 space-y-6">
          
          {/* STEP 1: SHIFT IDENTITY */}
          {step === 1 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Calendar className="w-5 h-5 text-amber-400" /> 1. የሺፍቱ ቀንና መረጃ (Shift Identity)
                </h3>
                <p className="text-xs text-gray-400">
                  መረጃውን ማስገባት የሚፈልጉበትን የካላንደር ቀን እና የሺፍት ዓይነት ይምረጡ።
                </p>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-2">
                  <div>
                    <label className="block text-xs font-semibold text-gray-300 mb-1.5">
                      የሺፍቱ ቀን (Date)
                    </label>
                    <input
                      type="date"
                      value={shiftDate}
                      onChange={e => setShiftDate(e.target.value)}
                      className="w-full bg-[#101522] border border-gray-700 rounded-xl px-3.5 py-2.5 text-white text-sm focus:border-amber-400 outline-none"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-gray-300 mb-1.5">
                      የሺፍት ዓይነት (Shift Type)
                    </label>
                    <div className="grid grid-cols-2 gap-2">
                      <button
                        type="button"
                        onClick={() => setShiftType('day')}
                        className={`flex items-center justify-center gap-2 py-2.5 px-3 rounded-xl border text-xs font-bold transition ${
                          shiftType === 'day'
                            ? 'bg-amber-500 text-black border-amber-400 shadow-md'
                            : 'bg-[#101522] text-gray-300 border-gray-700 hover:bg-gray-800'
                        }`}
                      >
                        <Sun className="w-4 h-4" /> ቀን (Day)
                      </button>
                      <button
                        type="button"
                        onClick={() => setShiftType('night')}
                        className={`flex items-center justify-center gap-2 py-2.5 px-3 rounded-xl border text-xs font-bold transition ${
                          shiftType === 'night'
                            ? 'bg-indigo-600 text-white border-indigo-400 shadow-md'
                            : 'bg-[#101522] text-gray-300 border-gray-700 hover:bg-gray-800'
                        }`}
                      >
                        <Moon className="w-4 h-4" /> ማታ (Night)
                      </button>
                    </div>
                  </div>

                  <div>
                    <label className="block text-xs font-semibold text-gray-300 mb-1.5">
                      የካሺየር ስም (Cashier Name)
                    </label>
                    <input
                      type="text"
                      value={cashierName}
                      onChange={e => setCashierName(e.target.value)}
                      placeholder="e.g. ሳራ መኮንን (Sara)"
                      className="w-full bg-[#101522] border border-gray-700 rounded-xl px-3.5 py-2.5 text-white text-sm focus:border-amber-400 outline-none"
                    />
                  </div>
                </div>
              </div>

              {/* Kitchen Lookup Summary Card */}
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800">
                <div className="flex items-center justify-between mb-3">
                  <h4 className="text-sm font-bold text-white flex items-center gap-2">
                    <Utensils className="w-4 h-4 text-orange-400" /> የኩሽና ማዘዣ ፍተሻ ውጤት (Kitchen Status)
                  </h4>
                  <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold ${
                    kitchenDataFound
                      ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                      : 'bg-gray-800 text-gray-400'
                  }`}>
                    {kitchenDataFound ? `${kitchenTicketsForShift.length} Tickets Found` : '0 Tickets (Blank Entry)'}
                  </span>
                </div>

                {kitchenDataFound ? (
                  <div className="space-y-3">
                    <p className="text-xs text-emerald-300">
                      በዚህ ቀን ለ{shiftType === 'day' ? 'ቀን' : 'ማታ'} ሺፍት በኩሽና የተዘጋጁ ምግቦች ዝርዝር ተገኝቷል፡
                    </p>
                    <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2">
                      {Object.entries(kitchenFoodSummary).map(([name, count]) => (
                        <div key={name} className="bg-[#101522] p-2.5 rounded-xl border border-gray-800 flex items-center justify-between">
                          <span className="text-xs text-gray-300 truncate mr-2">{name}</span>
                          <span className="text-xs font-bold text-amber-400 bg-amber-950/40 px-2 py-0.5 rounded-md">
                            {count}
                          </span>
                        </div>
                      ))}
                    </div>
                  </div>
                ) : (
                  <p className="text-xs text-gray-400">
                    በመረጡት ቀን በኩሽና አፕ የተመዘገበ ምንም ማዘዣ የለም። በደረጃ 4 እና 5 ያሉትን የምግብ ሣጥንና የሽያጭ መረጃዎች ሙሉ በሙሉ በእጅዎ መሙላት ይችላሉ።
                  </p>
                )}
              </div>
            </div>
          )}

          {/* STEP 2: JUICE INVENTORY (CUPS) */}
          {step === 2 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <Coffee className="w-5 h-5 text-amber-400" /> 2. የጁስ ኩባያ ቆጠራ (Juice Cup Inventory)
                </h3>
                <p className="text-xs text-gray-400">
                  የጁስ ዋጋ አንድ ወጥ (170 ETB) ስለሆነ አጠቃላይ ሽያጩ በመጀመሪያ በኩባያ ቆጠራ ይሰላል።
                </p>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 pt-2">
                  <div className="bg-[#101522] p-4 rounded-xl border border-gray-800">
                    <label className="block text-xs font-bold text-gray-300 mb-1">
                      1. መክፈቻ ኩባያ (Opening Cups)
                    </label>
                    <input
                      type="number"
                      value={openingCups}
                      onChange={e => setOpeningCups(e.target.value)}
                      placeholder="120"
                      className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-2 text-white text-lg font-bold outline-none focus:border-amber-400"
                    />
                  </div>

                  <div className="bg-[#101522] p-4 rounded-xl border border-gray-800">
                    <label className="block text-xs font-bold text-gray-300 mb-1">
                      2. ተጨማሪ ኩባያ (Added Cups)
                    </label>
                    <input
                      type="number"
                      value={addedCups}
                      onChange={e => setAddedCups(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-2 text-white text-lg font-bold outline-none focus:border-amber-400"
                    />
                  </div>

                  <div className="bg-[#101522] p-4 rounded-xl border border-gray-800">
                    <label className="block text-xs font-bold text-amber-400 mb-1">
                      3. ቀሪ ኩባያ (Leftover Cups)
                    </label>
                    <input
                      type="number"
                      value={leftoverCups}
                      onChange={e => setLeftoverCups(e.target.value)}
                      placeholder="ቀሪውን እዚህ ያስገቡ"
                      className="w-full bg-[#182032] border border-amber-500/50 rounded-lg px-3 py-2 text-white text-lg font-bold outline-none focus:border-amber-400"
                    />
                  </div>
                </div>

                {/* Auto Calculated Cups Banner */}
                <div className="bg-[#101522] p-4 rounded-xl border border-gray-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div>
                    <span className="text-xs text-gray-400">የተሸጠ ኩባያ ስሌት ((መክፈቻ + ተጨማሪ) - ቀሪ):</span>
                    <p className="text-2xl font-extrabold text-amber-400">
                      {calculatedCupsSold} ኩባያ (Cups Sold)
                    </p>
                  </div>
                  <div className="text-right">
                    <span className="text-xs text-gray-400">የተገመተ የጁስ ሽያጭ መጠን:</span>
                    <p className="text-xl font-bold text-white">
                      {(calculatedCupsSold * 170).toLocaleString()} ETB
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* STEP 3: JUICE SALES BY TYPE */}
          {step === 3 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center gap-2">
                    🍹 3. የጁስ ሽያጭ በዓይነት (Juice Sold by Type)
                  </h3>
                  <span className={`px-2.5 py-1 rounded-lg text-xs font-bold ${
                    totalJuiceSoldByType === calculatedCupsSold
                      ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                      : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                  }`}>
                    {totalJuiceSoldByType} / {calculatedCupsSold} Cups
                  </span>
                </div>
                <p className="text-xs text-gray-400">
                  በዚህ ሺፍት የተሸጡትን የጁስ ዓይነቶች ብዛት ያስገቡ (ጠቅላላው ከላይ ካለው {calculatedCupsSold} ኩባያ ጋር ቢመሳሰል ይመረጣል)።
                </p>

                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3 pt-2">
                  {juiceProducts.map(j => {
                    const count = juiceSoldMap[j.name] || '';
                    return (
                      <div key={j.id} className="bg-[#101522] p-3.5 rounded-xl border border-gray-800 flex items-center justify-between gap-3">
                        <div className="flex items-center gap-2.5 min-w-0">
                          <span className="text-2xl shrink-0">{j.emoji}</span>
                          <div className="min-w-0">
                            <h5 className="text-xs font-bold text-white truncate">{j.name}</h5>
                            <span className="text-[10px] text-gray-400">{j.price} ETB</span>
                          </div>
                        </div>
                        <input
                          type="number"
                          value={count}
                          onChange={e => {
                            const val = e.target.value === '' ? 0 : Number(e.target.value);
                            setJuiceSoldMap(prev => ({ ...prev, [j.name]: val }));
                          }}
                          placeholder="0"
                          className="w-16 bg-[#182032] border border-gray-700 rounded-lg px-2 py-1.5 text-center text-white text-sm font-bold outline-none focus:border-amber-400 shrink-0"
                        />
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {/* STEP 4: FOOD BOX INVENTORY */}
          {step === 4 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center gap-2">
                    🍱 4. የምግብ ሣጥን / ፖርሽን ቆጠራ (Food Box Inventory)
                  </h3>
                  {kitchenDataFound && (
                    <span className="px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                      Kitchen Ref Loaded
                    </span>
                  )}
                </div>
                <p className="text-xs text-gray-400">
                  የምግብ ዋጋዎች ስለሚለያዩ ለእያንዳንዱ ምግብ የመክፈቻና የቀሪ ሣጥን/ፖርሽን ቆጠራ ያስገቡ (ተበልቷል = መክፈቻ - ቀሪ)።
                </p>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="border-b border-gray-800 text-gray-400 font-semibold">
                        <th className="pb-3">የምግብ ዓይነት</th>
                        <th className="pb-3 text-center">ዋጋ (ETB)</th>
                        <th className="pb-3 text-center">መክፈቻ (Opening)</th>
                        <th className="pb-3 text-center">ቀሪ (Leftover)</th>
                        <th className="pb-3 text-center text-amber-400">ተበልቷል (Consumed)</th>
                        {kitchenDataFound && (
                          <th className="pb-3 text-center text-orange-400">ኩሽና ያበሰለው (Kitchen)</th>
                        )}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-800/60">
                      {foodProducts.map(p => {
                        const opening = foodBoxOpenings[p.name] ?? '';
                        const leftover = foodBoxLeftovers[p.name] ?? '';
                        const numOp = Number(opening) || 0;
                        const numLt = Number(leftover) || 0;
                        const consumed = Math.max(0, numOp - numLt);
                        const kitchenCooked = kitchenFoodSummary[p.name] || 0;

                        return (
                          <tr key={p.id} className="hover:bg-gray-800/30 transition">
                            <td className="py-2.5 pr-2 font-medium text-white flex items-center gap-2">
                              <span>{p.emoji}</span>
                              <span>{p.name}</span>
                            </td>
                            <td className="py-2.5 text-center text-gray-400">{p.price}</td>
                            <td className="py-2.5 text-center">
                              <input
                                type="number"
                                value={opening}
                                onChange={e => {
                                  const val = e.target.value === '' ? 0 : Number(e.target.value);
                                  setFoodBoxOpenings(prev => ({ ...prev, [p.name]: val }));
                                }}
                                placeholder="0"
                                className="w-16 bg-[#101522] border border-gray-700 rounded-lg px-2 py-1 text-center text-white text-xs font-bold outline-none focus:border-amber-400"
                              />
                            </td>
                            <td className="py-2.5 text-center">
                              <input
                                type="number"
                                value={leftover}
                                onChange={e => {
                                  const val = e.target.value === '' ? 0 : Number(e.target.value);
                                  setFoodBoxLeftovers(prev => ({ ...prev, [p.name]: val }));
                                }}
                                placeholder="0"
                                className="w-16 bg-[#101522] border border-gray-700 rounded-lg px-2 py-1 text-center text-white text-xs font-bold outline-none focus:border-amber-400"
                              />
                            </td>
                            <td className="py-2.5 text-center font-bold text-amber-400">
                              {consumed}
                            </td>
                            {kitchenDataFound && (
                              <td className="py-2.5 text-center font-bold text-orange-400">
                                {kitchenCooked}
                              </td>
                            )}
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* STEP 5: FOOD SOLD (WAITER) */}
          {step === 5 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center gap-2">
                    🍲 5. የምግብ ሽያጭ - አስተናጋጅ (Waiter Food Sold)
                  </h3>
                  <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-amber-500/20 text-amber-400 border border-amber-500/30">
                    Total Sold: {totalWaiterFoodSold} Dishes
                  </span>
                </div>
                <p className="text-xs text-gray-400">
                  አስተናጋጅ የሸጠችውን የምግብ ብዛት ያስገቡ። ከኩሽና ወይም ከሣጥን ቆጠራ ጋር ያለው ልዩነት በራስ-ሰር ይታያል።
                </p>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs">
                    <thead>
                      <tr className="border-b border-gray-800 text-gray-400 font-semibold">
                        <th className="pb-3">የምግብ ዓይነት</th>
                        <th className="pb-3 text-center">የተሸጠ ብዛት (Sold)</th>
                        <th className="pb-3 text-center text-amber-400">የሣጥን ቆጠራ (Consumed)</th>
                        {kitchenDataFound && (
                          <th className="pb-3 text-center text-orange-400">ኩሽና የተዘጋጀ (Kitchen)</th>
                        )}
                        <th className="pb-3 text-center">ልዩነት (Variance)</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-800/60">
                      {foodProducts.map(p => {
                        const sold = foodSoldMap[p.name] ?? '';
                        const numSold = Number(sold) || 0;
                        const opening = Number(foodBoxOpenings[p.name]) || 0;
                        const leftover = Number(foodBoxLeftovers[p.name]) || 0;
                        const consumed = Math.max(0, opening - leftover);
                        const kitchenCooked = kitchenFoodSummary[p.name] || 0;
                        const compareTarget = kitchenDataFound ? kitchenCooked : consumed;
                        const variance = numSold - compareTarget;

                        return (
                          <tr key={p.id} className="hover:bg-gray-800/30 transition">
                            <td className="py-2.5 pr-2 font-medium text-white flex items-center gap-2">
                              <span>{p.emoji}</span>
                              <span>{p.name}</span>
                            </td>
                            <td className="py-2.5 text-center">
                              <input
                                type="number"
                                value={sold}
                                onChange={e => {
                                  const val = e.target.value === '' ? 0 : Number(e.target.value);
                                  setFoodSoldMap(prev => ({ ...prev, [p.name]: val }));
                                }}
                                placeholder="0"
                                className="w-16 bg-[#101522] border border-gray-700 rounded-lg px-2 py-1 text-center text-white text-xs font-bold outline-none focus:border-amber-400"
                              />
                            </td>
                            <td className="py-2.5 text-center font-bold text-amber-400">
                              {consumed}
                            </td>
                            {kitchenDataFound && (
                              <td className="py-2.5 text-center font-bold text-orange-400">
                                {kitchenCooked}
                              </td>
                            )}
                            <td className="py-2.5 text-center">
                              <span className={`px-2 py-0.5 rounded text-[11px] font-bold ${
                                variance === 0
                                  ? 'bg-emerald-500/20 text-emerald-400'
                                  : variance > 0
                                  ? 'bg-blue-500/20 text-blue-400'
                                  : 'bg-red-500/20 text-red-400'
                              }`}>
                                {variance > 0 ? `+${variance}` : variance}
                              </span>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* STEP 6: SALES BREAKDOWN */}
          {step === 6 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <h3 className="text-base font-bold text-white flex items-center gap-2">
                  <DollarSign className="w-5 h-5 text-emerald-400" /> 6. የሽያጭ ክፍፍል (Sales Breakdown)
                </h3>
                <p className="text-xs text-gray-400">
                  የጥሬ ገንዘብ፣ የባንክ ትራንስፈር፣ የብድር/አዳሪ እና የዴሊቨሪ ሽያጮችን ያስገቡ።
                </p>

                <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 pt-2">
                  <div className="bg-[#101522] p-4 rounded-xl border border-gray-800">
                    <label className="block text-xs font-bold text-emerald-400 mb-1 flex items-center gap-1.5">
                      <Wallet className="w-4 h-4" /> ጥሬ ገንዘብ ሽያጭ (Cash Sales ETB)
                    </label>
                    <input
                      type="number"
                      value={cashSales}
                      onChange={e => setCashSales(e.target.value)}
                      placeholder="0.00"
                      className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-2 text-white text-lg font-bold outline-none focus:border-emerald-400"
                    />
                  </div>

                  <div className="bg-[#101522] p-4 rounded-xl border border-gray-800">
                    <label className="block text-xs font-bold text-cyan-400 mb-1 flex items-center gap-1.5">
                      <Smartphone className="w-4 h-4" /> ባንክ / ቴሌብር (Transfer Total ETB)
                    </label>
                    <input
                      type="number"
                      value={transferSales}
                      onChange={e => setTransferSales(e.target.value)}
                      placeholder="0.00"
                      className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-2 text-white text-lg font-bold outline-none focus:border-cyan-400"
                    />
                    <small className="text-[10px] text-gray-400">ደረጃ 7 ላይ ዝርዝሩን ያረጋግጣሉ</small>
                  </div>

                  <div className="bg-[#101522] p-4 rounded-xl border border-gray-800">
                    <label className="block text-xs font-bold text-amber-400 mb-1 flex items-center gap-1.5">
                      <CreditCard className="w-4 h-4" /> አዳሪ / ብድር (Credit Sales ETB)
                    </label>
                    <input
                      type="number"
                      value={creditSales}
                      onChange={e => setCreditSales(e.target.value)}
                      placeholder="0.00"
                      className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-2 text-white text-lg font-bold outline-none focus:border-amber-400"
                    />
                  </div>

                  <div className="bg-[#101522] p-4 rounded-xl border border-gray-800">
                    <label className="block text-xs font-bold text-purple-400 mb-1 flex items-center gap-1.5">
                      <Truck className="w-4 h-4" /> ዴሊቨሪ ሽያጭ (Delivery Sales ETB)
                    </label>
                    <input
                      type="number"
                      value={deliverySales}
                      onChange={e => setDeliverySales(e.target.value)}
                      placeholder="0.00"
                      className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-2 text-white text-lg font-bold outline-none focus:border-purple-400"
                    />
                  </div>

                  <div className="bg-[#101522] p-4 rounded-xl border border-gray-800">
                    <label className="block text-xs font-bold text-gray-300 mb-1 flex items-center gap-1.5">
                      <Receipt className="w-4 h-4" /> ጉርሻ / ቲፕ (Tip ETB)
                    </label>
                    <input
                      type="number"
                      value={tipSales}
                      onChange={e => setTipSales(e.target.value)}
                      placeholder="0.00"
                      className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-2 text-white text-lg font-bold outline-none focus:border-gray-400"
                    />
                  </div>

                  <div className="bg-[#101522] p-4 rounded-xl border border-gray-800">
                    <label className="block text-xs font-bold text-gray-300 mb-1">
                      ጠቅላላ የኦርደር ብዛት (Orders Count)
                    </label>
                    <input
                      type="number"
                      value={totalOrdersCount}
                      onChange={e => setTotalOrdersCount(e.target.value)}
                      placeholder="0"
                      className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-2 text-white text-lg font-bold outline-none focus:border-gray-400"
                    />
                  </div>
                </div>

                {/* Total Gross Revenue Banner */}
                <div className="bg-gradient-to-r from-emerald-950/80 to-[#101522] p-4 rounded-xl border border-emerald-500/30 flex items-center justify-between">
                  <div>
                    <span className="text-xs text-emerald-400 font-bold uppercase tracking-wider">
                      ጠቅላላ ገቢ (Gross Revenue)
                    </span>
                    <p className="text-2xl font-extrabold text-white">
                      {grossRevenue.toLocaleString('en-US', { minimumFractionDigits: 2 })} ETB
                    </p>
                  </div>
                  <span className="text-xs text-gray-400">
                    = Cash + Transfer + Credit + Delivery + Tip
                  </span>
                </div>
              </div>
            </div>
          )}

          {/* STEP 7: TRANSFER RECORDS */}
          {step === 7 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center gap-2">
                    <Smartphone className="w-5 h-5 text-cyan-400" /> 7. የባንክና ቴሌብር ዝርዝር (Transfer Records)
                  </h3>
                  <div className="flex items-center gap-2">
                    <span className={`px-2.5 py-1 rounded-lg text-xs font-bold ${
                      totalTransfersLogged === numTransfer
                        ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                        : 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                    }`}>
                      Logged: {totalTransfersLogged.toLocaleString()} / Expected: {numTransfer.toLocaleString()} ETB
                    </span>
                    <button
                      type="button"
                      onClick={handleAddTransfer}
                      className="px-3 py-1 bg-cyan-600 hover:bg-cyan-500 text-white rounded-lg text-xs font-bold flex items-center gap-1"
                    >
                      <Plus className="w-3.5 h-3.5" /> አክል (Add)
                    </button>
                  </div>
                </div>
                <p className="text-xs text-gray-400">
                  የላኪውን ስም፣ የገንዘቡን መጠን እና የትራንስፈሩን ዓይነት (ቴሌብር/CBE) ያስገቡ።
                </p>

                <div className="space-y-2.5 pt-1">
                  {transfers.map((tf, index) => (
                    <div key={tf.id} className="bg-[#101522] p-3 rounded-xl border border-gray-800 grid grid-cols-1 sm:grid-cols-12 gap-2 items-center">
                      <div className="sm:col-span-1 text-center text-xs font-bold text-gray-400">
                        #{index + 1}
                      </div>
                      <div className="sm:col-span-4">
                        <input
                          type="text"
                          value={tf.senderName}
                          onChange={e => handleUpdateTransfer(tf.id, 'senderName', e.target.value)}
                          placeholder="የላኪው ስም (Sender Name)"
                          className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs outline-none focus:border-cyan-400"
                        />
                      </div>
                      <div className="sm:col-span-3">
                        <input
                          type="number"
                          value={tf.amount || ''}
                          onChange={e => handleUpdateTransfer(tf.id, 'amount', e.target.value)}
                          placeholder="መጠን (Amount ETB)"
                          className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs font-bold outline-none focus:border-cyan-400"
                        />
                      </div>
                      <div className="sm:col-span-3">
                        <input
                          type="text"
                          value={tf.note}
                          onChange={e => handleUpdateTransfer(tf.id, 'note', e.target.value)}
                          placeholder="ማስታወሻ (e.g. Telebirr, CBE)"
                          className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs outline-none focus:border-cyan-400"
                        />
                      </div>
                      <div className="sm:col-span-1 text-right">
                        <button
                          type="button"
                          onClick={() => handleRemoveTransfer(tf.id)}
                          className="p-1.5 text-red-400 hover:text-red-300 hover:bg-red-950/40 rounded-lg"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* STEP 8: SHIFT EXPENSES */}
          {step === 8 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center gap-2">
                    <Receipt className="w-5 h-5 text-red-400" /> 8. የሺፍቱ ወጪዎች (Shift Expenses)
                  </h3>
                  <div className="flex items-center gap-2">
                    <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-red-500/20 text-red-400 border border-red-500/30">
                      Total: {totalExpenses.toLocaleString()} ETB
                    </span>
                    <button
                      type="button"
                      onClick={handleAddExpense}
                      className="px-3 py-1 bg-red-600 hover:bg-red-500 text-white rounded-lg text-xs font-bold flex items-center gap-1"
                    >
                      <Plus className="w-3.5 h-3.5" /> ወጪ አክል (Add Expense)
                    </button>
                  </div>
                </div>
                <p className="text-xs text-gray-400">
                  በዚህ ሺፍት ከካሽ የተከፈሉ ወጪዎችን ይመዝግቡ (ከመጨረሻው ጥሬ ገንዘብ ላይ ይቀነሳል)።
                </p>

                <div className="space-y-2.5 pt-1">
                  {expenses.map((exp, index) => (
                    <div key={exp.id} className="bg-[#101522] p-3 rounded-xl border border-gray-800 grid grid-cols-1 sm:grid-cols-12 gap-2 items-center">
                      <div className="sm:col-span-1 text-center text-xs font-bold text-gray-400">
                        #{index + 1}
                      </div>
                      <div className="sm:col-span-3">
                        <select
                          value={exp.category}
                          onChange={e => handleUpdateExpense(exp.id, 'category', e.target.value)}
                          className="w-full bg-[#182032] border border-gray-700 rounded-lg px-2.5 py-1.5 text-white text-xs outline-none focus:border-red-400"
                        >
                          <option value="Kitchen supplies">Kitchen supplies</option>
                          <option value="Fruit purchase">Fruit purchase (ፍራፍሬ)</option>
                          <option value="Staff meal">Staff meal (የሰራተኛ)</option>
                          <option value="Transport">Transport (ትራንስፖርት)</option>
                          <option value="Maintenance">Maintenance (ጥገና)</option>
                          <option value="Miscellaneous">Miscellaneous (ሌላ)</option>
                        </select>
                      </div>
                      <div className="sm:col-span-4">
                        <input
                          type="text"
                          value={exp.description}
                          onChange={e => handleUpdateExpense(exp.id, 'description', e.target.value)}
                          placeholder="የወጪው ዝርዝር መግለጫ (Description)"
                          className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs outline-none focus:border-red-400"
                        />
                      </div>
                      <div className="sm:col-span-3">
                        <input
                          type="number"
                          value={exp.amount || ''}
                          onChange={e => handleUpdateExpense(exp.id, 'amount', e.target.value)}
                          placeholder="መጠን (Amount ETB)"
                          className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs font-bold outline-none focus:border-red-400"
                        />
                      </div>
                      <div className="sm:col-span-1 text-right">
                        <button
                          type="button"
                          onClick={() => handleRemoveExpense(exp.id)}
                          className="p-1.5 text-red-400 hover:text-red-300 hover:bg-red-950/40 rounded-lg"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* STEP 9: PENDING PAYMENTS (NEW DEBTS) */}
          {step === 9 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center gap-2">
                    <CreditCard className="w-5 h-5 text-amber-400" /> 9. አዳዲስ አዳሪ / ብድር (New Pending Debts)
                  </h3>
                  <div className="flex items-center gap-2">
                    <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-amber-500/20 text-amber-400 border border-amber-500/30">
                      Total: {totalNewDebts.toLocaleString()} ETB
                    </span>
                    <button
                      type="button"
                      onClick={handleAddPendingPayment}
                      className="px-3 py-1 bg-amber-600 hover:bg-amber-500 text-white rounded-lg text-xs font-bold flex items-center gap-1"
                    >
                      <Plus className="w-3.5 h-3.5" /> አዳሪ አክል (Add Debt)
                    </button>
                  </div>
                </div>
                <p className="text-xs text-gray-400">
                  በዚህ ሺፍት የተፈጠሩ ያልተከፈሉ አዳዲስ የደንበኛ እዳዎችን ይመዝግቡ (በራስ-ሰር ወደ ደንበኛ እዳ ዝርዝር ውስጥ ይገባሉ)።
                </p>

                {pendingPayments.length === 0 ? (
                  <div className="bg-[#101522] p-6 rounded-xl border border-gray-800 text-center text-gray-400 text-xs">
                    ምንም አዲስ ያልተከፈለ አዳሪ የለም። ካለ &quot;አዳሪ አክል&quot; የሚለውን ይጫኑ።
                  </div>
                ) : (
                  <div className="space-y-2.5 pt-1">
                    {pendingPayments.map((p, index) => (
                      <div key={p.id} className="bg-[#101522] p-3 rounded-xl border border-gray-800 grid grid-cols-1 sm:grid-cols-12 gap-2 items-center">
                        <div className="sm:col-span-1 text-center text-xs font-bold text-gray-400">
                          #{index + 1}
                        </div>
                        <div className="sm:col-span-4">
                          <input
                            type="text"
                            value={p.customerName}
                            onChange={e => handleUpdatePendingPayment(p.id, 'customerName', e.target.value)}
                            placeholder="የደንበኛ ስም (Customer Name)"
                            className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs outline-none focus:border-amber-400"
                          />
                        </div>
                        <div className="sm:col-span-3">
                          <input
                            type="number"
                            value={p.amount || ''}
                            onChange={e => handleUpdatePendingPayment(p.id, 'amount', e.target.value)}
                            placeholder="መጠን (Amount ETB)"
                            className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs font-bold outline-none focus:border-amber-400"
                          />
                        </div>
                        <div className="sm:col-span-3">
                          <input
                            type="text"
                            value={p.note}
                            onChange={e => handleUpdatePendingPayment(p.id, 'note', e.target.value)}
                            placeholder="ማስታወሻ (e.g. 2 ጁስ አዳሪ)"
                            className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs outline-none focus:border-amber-400"
                          />
                        </div>
                        <div className="sm:col-span-1 text-right">
                          <button
                            type="button"
                            onClick={() => handleRemovePendingPayment(p.id)}
                            className="p-1.5 text-red-400 hover:text-red-300 hover:bg-red-950/40 rounded-lg"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}

          {/* STEP 10: RECOVERED PAYMENTS */}
          {step === 10 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center gap-2">
                    <CheckCircle2 className="w-5 h-5 text-emerald-400" /> 10. የተሰበሰበ አዳሪ / ብድር (Recovered Payments)
                  </h3>
                  <div className="flex items-center gap-2">
                    <span className="px-2.5 py-1 rounded-lg text-xs font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                      Total: {totalRecoveredDebts.toLocaleString()} ETB
                    </span>
                    <button
                      type="button"
                      onClick={handleAddCustomRecovery}
                      className="px-3 py-1 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs font-bold flex items-center gap-1"
                    >
                      <Plus className="w-3.5 h-3.5" /> ሌላ ሰብስብ (Custom)
                    </button>
                  </div>
                </div>
                <p className="text-xs text-gray-400">
                  በዚህ ሺፍት የተከፈሉ የነበሩ የቆዩ አዳሪዎችን ይምረጡ (ወደ ጥሬ ገንዘብ ርክክብ ይደመራል)።
                </p>

                {/* Active Debts in System */}
                <div className="space-y-2">
                  <h4 className="text-xs font-bold text-gray-300 uppercase tracking-wider">
                    በሲስተም ውስጥ ያሉ ክፍት አዳሪዎች (Existing Debts)
                  </h4>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {initialDebts.filter(d => !d.isRecovered).map(d => {
                      const isSelected = !!selectedDebts[d.id];
                      return (
                        <div
                          key={d.id}
                          onClick={() => setSelectedDebts(prev => ({ ...prev, [d.id]: !prev[d.id] }))}
                          className={`p-3.5 rounded-xl border cursor-pointer transition flex items-center justify-between ${
                            isSelected
                              ? 'bg-emerald-950/60 border-emerald-500/60 shadow-lg'
                              : 'bg-[#101522] border-gray-800 hover:border-gray-700'
                          }`}
                        >
                          <div className="flex items-center gap-3">
                            <div className={`w-5 h-5 rounded-md flex items-center justify-center border ${
                              isSelected ? 'bg-emerald-500 border-emerald-400 text-black' : 'border-gray-700'
                            }`}>
                              {isSelected && <Check className="w-3.5 h-3.5 stroke-[3]" />}
                            </div>
                            <div>
                              <h5 className="text-xs font-bold text-white">{d.customerName}</h5>
                              <p className="text-[10px] text-gray-400">{d.note || 'No note'} • {d.cupCount} Cups</p>
                            </div>
                          </div>
                          <span className="text-xs font-extrabold text-emerald-400">
                            {d.amount.toLocaleString()} ETB
                          </span>
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* Custom Recoveries */}
                {customRecoveries.length > 0 && (
                  <div className="space-y-2 pt-3 border-t border-gray-800">
                    <h4 className="text-xs font-bold text-gray-300 uppercase tracking-wider">
                      በእጅ የተጨመሩ የተሰበሰቡ እዳዎች (Custom Recovered)
                    </h4>
                    {customRecoveries.map(cr => (
                      <div key={cr.debtId} className="bg-[#101522] p-3 rounded-xl border border-gray-800 grid grid-cols-1 sm:grid-cols-12 gap-2 items-center">
                        <div className="sm:col-span-6">
                          <input
                            type="text"
                            value={cr.customerName}
                            onChange={e => handleUpdateCustomRecovery(cr.debtId, 'customerName', e.target.value)}
                            placeholder="የከፈለው ደንበኛ ስም (Customer Name)"
                            className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs outline-none focus:border-emerald-400"
                          />
                        </div>
                        <div className="sm:col-span-5">
                          <input
                            type="number"
                            value={cr.amount || ''}
                            onChange={e => handleUpdateCustomRecovery(cr.debtId, 'amount', e.target.value)}
                            placeholder="የተከፈለው መጠን (Amount ETB)"
                            className="w-full bg-[#182032] border border-gray-700 rounded-lg px-3 py-1.5 text-white text-xs font-bold outline-none focus:border-emerald-400"
                          />
                        </div>
                        <div className="sm:col-span-1 text-right">
                          <button
                            type="button"
                            onClick={() => handleRemoveCustomRecovery(cr.debtId)}
                            className="p-1.5 text-red-400 hover:text-red-300 hover:bg-red-950/40 rounded-lg"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}

          {/* STEP 11: SUMMARY & HANDOVER */}
          {step === 11 && (
            <div className="space-y-5 animate-fadeIn">
              <div className="bg-[#182032] p-5 rounded-2xl border border-gray-800 space-y-5">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-bold text-white flex items-center gap-2">
                    <ShieldCheck className="w-5 h-5 text-emerald-400" /> 11. የመጨረሻ ማጠቃለያና የጥሬ ገንዘብ ርክክብ (Summary &amp; Handover)
                  </h3>
                  <span className="px-3 py-1 bg-purple-500/20 text-purple-300 border border-purple-500/30 rounded-lg text-xs font-bold">
                    {shiftDate} • {shiftType === 'day' ? 'Day Shift' : 'Night Shift'}
                  </span>
                </div>

                {/* Main Metrics Breakdown Grid */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  <div className="bg-[#101522] p-3.5 rounded-xl border border-gray-800">
                    <span className="text-[10px] text-gray-400 uppercase font-bold">ጠቅላላ ገቢ</span>
                    <p className="text-base font-extrabold text-white">{grossRevenue.toLocaleString()} ETB</p>
                  </div>
                  <div className="bg-[#101522] p-3.5 rounded-xl border border-gray-800">
                    <span className="text-[10px] text-emerald-400 uppercase font-bold">ጥሬ ገንዘብ ሽያጭ</span>
                    <p className="text-base font-extrabold text-emerald-400">+{numCash.toLocaleString()} ETB</p>
                  </div>
                  <div className="bg-[#101522] p-3.5 rounded-xl border border-gray-800">
                    <span className="text-[10px] text-emerald-400 uppercase font-bold">የተሰበሰበ አዳሪ</span>
                    <p className="text-base font-extrabold text-emerald-400">+{totalRecoveredDebts.toLocaleString()} ETB</p>
                  </div>
                  <div className="bg-[#101522] p-3.5 rounded-xl border border-gray-800">
                    <span className="text-[10px] text-red-400 uppercase font-bold">የሺፍቱ ወጪዎች</span>
                    <p className="text-base font-extrabold text-red-400">-{totalExpenses.toLocaleString()} ETB</p>
                  </div>
                </div>

                {/* Final Net Cash Handover Big Card */}
                <div className="bg-gradient-to-br from-emerald-950 via-[#122220] to-[#101522] p-6 rounded-2xl border-2 border-emerald-500/50 shadow-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <Wallet className="w-6 h-6 text-emerald-400" />
                      <span className="text-sm font-extrabold text-emerald-300 uppercase tracking-wider">
                        ለባለቤቱ የሚረከብ ጥሬ ገንዘብ (Net Cash to Owner)
                      </span>
                    </div>
                    <p className="text-3xl sm:text-4xl font-black text-white tracking-tight">
                      {netCashToOwner.toLocaleString('en-US', { minimumFractionDigits: 2 })} ETB
                    </p>
                    <p className="text-xs text-gray-300 mt-1">
                      = Cash ({numCash}) + Recovered ({totalRecoveredDebts}) – Expenses ({totalExpenses})
                    </p>
                  </div>
                </div>

                {/* Inventory Cross-check overview */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                  <div className="bg-[#101522] p-3.5 rounded-xl border border-gray-800">
                    <h5 className="text-xs font-bold text-gray-300 mb-1 flex items-center gap-1.5">
                      <Coffee className="w-4 h-4 text-amber-400" /> ጁስ ኩባያ ቆጠራ
                    </h5>
                    <p className="text-xs text-gray-400">
                      የተሸጠ: <strong className="text-white">{calculatedCupsSold} ኩባያ</strong> ({calculatedCupsSold * 170} ETB)
                    </p>
                  </div>

                  <div className="bg-[#101522] p-3.5 rounded-xl border border-gray-800">
                    <h5 className="text-xs font-bold text-gray-300 mb-1 flex items-center gap-1.5">
                      <Utensils className="w-4 h-4 text-orange-400" /> ምግብ ማመሳከሪያ
                    </h5>
                    <p className="text-xs text-gray-400">
                      አስተናጋጅ: <strong className="text-white">{totalWaiterFoodSold}</strong> | ኩሽና: <strong className="text-white">{totalKitchenCookedCount}</strong>
                    </p>
                  </div>
                </div>

                {/* Shift Notes */}
                <div>
                  <label className="block text-xs font-semibold text-gray-300 mb-1.5">
                    የሺፍቱ ተጨማሪ ማስታወሻ (Shift Notes / Remarks)
                  </label>
                  <textarea
                    value={shiftNotes}
                    onChange={e => setShiftNotes(e.target.value)}
                    rows={2}
                    placeholder="ለዚህ ሺፍት የተለየ ማስታወሻ ካለ እዚህ ይጻፉ..."
                    className="w-full bg-[#101522] border border-gray-700 rounded-xl p-3 text-white text-xs outline-none focus:border-amber-400 resize-none"
                  />
                </div>
              </div>
            </div>
          )}

        </div>

        {/* FOOTER ACTIONS */}
        <div className="p-4 md:px-6 bg-[#1a2234] border-t border-gray-800 flex items-center justify-between">
          <button
            type="button"
            onClick={() => setStep(prev => Math.max(1, prev - 1))}
            disabled={step === 1}
            className={`px-4 py-2.5 rounded-xl text-xs font-bold flex items-center gap-1.5 transition ${
              step === 1
                ? 'opacity-40 cursor-not-allowed text-gray-500 bg-gray-800/40'
                : 'text-gray-200 bg-gray-800 hover:bg-gray-700'
            }`}
          >
            <ArrowLeft className="w-4 h-4" /> ወደ ኋላ (Back)
          </button>

          <div className="flex items-center gap-2">
            {step < 11 ? (
              <button
                type="button"
                onClick={() => setStep(prev => Math.min(11, prev + 1))}
                className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-400 text-black text-xs font-extrabold flex items-center gap-1.5 shadow-lg transition"
              >
                ቀጣይ (Next) <ArrowRight className="w-4 h-4" />
              </button>
            ) : (
              <button
                type="button"
                onClick={handleSubmit}
                disabled={isSubmitting}
                className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-400 hover:to-teal-400 text-black text-xs font-black flex items-center gap-2 shadow-xl transition active:scale-95"
              >
                {isSubmitting ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" /> በማስቀመጥ ላይ...
                  </>
                ) : (
                  <>
                    <Check className="w-4 h-4 stroke-[3]" /> አስቀምጥና አጠናቅቅ (Submit Reconciliation)
                  </>
                )}
              </button>
            )}
          </div>
        </div>

      </div>
    </div>
  );
}
