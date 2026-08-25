'use client';

import React, { useState, useMemo } from 'react';
import {
  X, Check, ArrowRight, ArrowLeft, Plus, Trash2, DollarSign, Wallet, Smartphone,
  CreditCard, Truck, AlertCircle, Lock, Receipt, ShieldCheck, Utensils
} from 'lucide-react';
import { ShiftSession, Order, ShiftExpense, CustomerDebt, ShiftReconciliation, KitchenTicket, FoodItemReconciliation } from '../types/pos';
import { dataService } from '../lib/dataService';
import { PinPadModal } from './PinPadModal';

interface ShiftReconciliationModalProps {
  shiftSession: ShiftSession;
  orders: Order[];
  initialDebts: CustomerDebt[];
  cupsSold: number;
  kitchenTickets?: KitchenTicket[];
  onClose: () => void;
  onCompleteReconciliation: (recon: ShiftReconciliation) => void;
}

export function ShiftReconciliationModal({
  shiftSession,
  orders,
  initialDebts,
  cupsSold,
  kitchenTickets,
  onClose,
  onCompleteReconciliation,
}: ShiftReconciliationModalProps) {
  const [step, setStep] = useState<number>(1);
  const [showPinModal, setShowPinModal] = useState<boolean>(false);

  // Step 2 state: Cup Inventory (Starts blind/empty)
  const [openingCups, setOpeningCups] = useState<string>(String(shiftSession.openingCups || 120));
  const [addedCups, setAddedCups] = useState<string>('0');
  const [leftoverCups, setLeftoverCups] = useState<string>('');

  const numOpening = openingCups === '' ? 0 : Number(openingCups);
  const numAdded = addedCups === '' ? 0 : Number(addedCups);
  const numLeftover = leftoverCups === '' ? null : Number(leftoverCups);

  // Calculated Sold = (Opening + Added) - Leftover
  const calculatedCupsSold = numLeftover !== null ? Math.max(0, (numOpening + numAdded) - numLeftover) : 0;
  const cupsVariance = numLeftover !== null ? calculatedCupsSold - cupsSold : null;
  const isCupCountEntered = numLeftover !== null && !isNaN(numLeftover);
  const isCupCountMatched = isCupCountEntered && cupsVariance === 0;

  // Step 2 Part B: Food Cross-Check (Kitchen Cooked vs Waiter Registered Sales)
  const shiftRouteName = shiftSession.shiftType === 'day' ? 'Day shift' : 'Night shift';
  const allKitchenTickets = kitchenTickets || dataService.getKitchenTickets();
  const relevantKitchenTickets = useMemo(() => {
    return allKitchenTickets.filter(t => t.route === shiftRouteName);
  }, [allKitchenTickets, shiftRouteName]);

  // Aggregate kitchen cooked food items
  const kitchenFoodSummary = useMemo(() => {
    const map: { [name: string]: { count: number; emoji?: string } } = {};
    relevantKitchenTickets.forEach(ticket => {
      ticket.items.forEach(item => {
        if (!map[item.name]) {
          map[item.name] = { count: 0, emoji: item.emoji };
        }
        map[item.name].count += item.quantity;
      });
    });
    return map;
  }, [relevantKitchenTickets]);

  // Aggregate waiter sold food items
  const waiterFoodSummary = useMemo(() => {
    const map: { [name: string]: { count: number; emoji?: string } } = {};
    orders.forEach(order => {
      order.items.forEach(item => {
        if (item.category === 'Food') {
          if (!map[item.name]) {
            map[item.name] = { count: 0, emoji: item.emoji };
          }
          map[item.name].count += item.quantity;
        }
      });
    });
    return map;
  }, [orders]);

  const allFoodNames = useMemo(() => {
    return Array.from(
      new Set([...Object.keys(kitchenFoodSummary), ...Object.keys(waiterFoodSummary)])
    );
  }, [kitchenFoodSummary, waiterFoodSummary]);

  const foodItemsReconciliation: FoodItemReconciliation[] = useMemo(() => {
    return allFoodNames.map(foodName => {
      const cooked = kitchenFoodSummary[foodName]?.count || 0;
      const sold = waiterFoodSummary[foodName]?.count || 0;
      const emoji = kitchenFoodSummary[foodName]?.emoji || waiterFoodSummary[foodName]?.emoji || '🍲';
      return {
        id: foodName,
        name: foodName,
        emoji,
        kitchenCookedCount: cooked,
        waiterSoldCount: sold,
        variance: sold - cooked,
      };
    });
  }, [allFoodNames, kitchenFoodSummary, waiterFoodSummary]);

  const totalKitchenFoodCooked = useMemo(() => {
    return Object.values(kitchenFoodSummary).reduce((sum, f) => sum + f.count, 0);
  }, [kitchenFoodSummary]);

  const totalWaiterFoodSold = useMemo(() => {
    return Object.values(waiterFoodSummary).reduce((sum, f) => sum + f.count, 0);
  }, [waiterFoodSummary]);

  const foodVariance = totalWaiterFoodSold - totalKitchenFoodCooked;

  // Strict Food Gate: If kitchen dispatched food for this shift, waiter sold count cannot be less than cooked count
  const isFoodCountMatched = totalKitchenFoodCooked === 0 || totalWaiterFoodSold >= totalKitchenFoodCooked;

  const canProceedStep2 = isCupCountMatched && isFoodCountMatched;

  // Step 3 state: Daily Expenses
  const [expenses, setExpenses] = useState<ShiftExpense[]>([
    { id: 'exp-1', shiftId: shiftSession.id, category: 'ሎሚ (Lemons)', description: 'ለጁስ የሚሆን ሎሚ', amount: 150, loggedAt: new Date().toISOString() },
    { id: 'exp-2', shiftId: shiftSession.id, category: 'በረዶ (Ice)', description: '2 ኮረጆ የበረዶ ውሃ', amount: 200, loggedAt: new Date().toISOString() },
  ]);
  const [expenseCat, setExpenseCat] = useState<string>('ሎሚ (Lemons)');
  const [expenseDesc, setExpenseDesc] = useState<string>('');
  const [expenseAmount, setExpenseAmount] = useState<string>('');

  // Step 4 state: Pooled Pending Cups — cashier enters how many cups were collected today
  const totalPendingCups = initialDebts.reduce((sum, d) => sum + (d.isRecovered ? 0 : d.cupCount), 0);
  const PRICE_PER_CUP = 170;
  const [cupsCollectedToday, setCupsCollectedToday] = useState<string>('0');
  const numCupsCollected = cupsCollectedToday === '' ? 0 : Number(cupsCollectedToday);
  const totalRecoveredCups = Math.min(numCupsCollected, totalPendingCups);
  const totalRecoveredDebts = totalRecoveredCups * PRICE_PER_CUP;
  const remainingPendingCups = totalPendingCups - totalRecoveredCups;

  // Step 5 state: Cash Handover & Notes
  const [shiftNotes, setShiftNotes] = useState<string>('');

  // Sales Calculations (ETB)
  const grossRevenue = orders.reduce((sum, o) => sum + o.total, 0);
  const cashSales = orders.filter(o => o.paymentMethod === 'Cash').reduce((sum, o) => sum + o.total, 0);
  const transferSales = orders.filter(o => o.paymentMethod === 'Transfer').reduce((sum, o) => sum + o.total, 0);
  const creditSales = orders.filter(o => o.paymentMethod === 'Credit' || o.paymentMethod === 'Pay later').reduce((sum, o) => sum + o.total, 0);
  const deliverySales = orders.filter(o => o.paymentMethod === 'Delivery').reduce((sum, o) => sum + o.total, 0);
  const tipSales = 0;

  const totalExpenses = expenses.reduce((sum, e) => sum + e.amount, 0);
  const totalPendingETB = totalPendingCups * PRICE_PER_CUP;

  // Net Cash to Owner = Today's Cash Sales + Recovered Debts Cash - Daily Shift Expenses (ETB)
  const netCashToOwner = cashSales + totalRecoveredDebts - totalExpenses;

  // Expense Quick Add Handlers
  const handleAddQuickExpense = (category: string, amount: number) => {
    const newExp: ShiftExpense = {
      id: `exp-${Date.now()}`,
      shiftId: shiftSession.id,
      category,
      description: `${category} ወጪ`,
      amount,
      loggedAt: new Date().toISOString()
    };
    setExpenses(prev => [...prev, newExp]);
  };

  const handleCustomExpenseAdd = (e: React.FormEvent) => {
    e.preventDefault();
    if (!expenseAmount || Number(expenseAmount) <= 0) return;
    const newExp: ShiftExpense = {
      id: `exp-${Date.now()}`,
      shiftId: shiftSession.id,
      category: expenseCat,
      description: expenseDesc || `${expenseCat} ግዢ`,
      amount: Number(expenseAmount),
      loggedAt: new Date().toISOString()
    };
    setExpenses(prev => [...prev, newExp]);
    setExpenseDesc('');
    setExpenseAmount('');
  };

  const handleDeleteExpense = (id: string) => {
    setExpenses(prev => prev.filter(e => e.id !== id));
  };

  // (Pooled debt — no per-customer toggle needed)

  // Submit & Close Shift
  const handleFinalSubmit = (pin: string) => {
    const finalLeftover = numLeftover !== null ? numLeftover : 0;
    const finalVariance = cupsVariance !== null ? cupsVariance : 0;

    const reconciliationRecord: ShiftReconciliation = {
      id: `recon-${Date.now()}`,
      shiftId: shiftSession.id,
      shiftType: shiftSession.shiftType,
      cashierName: shiftSession.cashierName || 'ሳራ መኮንን',
      grossRevenue,
      cashSales,
      transferSales,
      creditSales,
      deliverySales,
      tipSales,
      totalOrdersCount: orders.length,
      openingCups: numOpening,
      addedCups: numAdded,
      leftoverCups: finalLeftover,
      calculatedCupsSold,
      tabletCupsSold: cupsSold,
      cupsVariance: finalVariance,
      totalKitchenFoodCooked,
      totalWaiterFoodSold,
      foodVariance,
      foodItemsReconciliation,
      totalExpenses,
      expenses,
      totalRecoveredCups,
      totalRecoveredDebts,
      recoveredDebts: [],
      netCashToOwner,
      shiftNotes,
      closedAt: new Date().toISOString()
    };

    setShowPinModal(false);
    onCompleteReconciliation(reconciliationRecord);
  };

  const progressPercent = step * 20;

  return (
    <div className="modal-backdrop z-50 overflow-y-auto py-6">
      <div className="reconcile-modal max-w-3xl w-full bg-white rounded-2xl shadow-2xl overflow-hidden border border-gray-200 flex flex-col max-h-[92vh] my-auto">
        {/* Header with Logo (Fixed) */}
        <div className="modal-top border-b border-gray-100 p-4 sm:p-5 flex items-center justify-between shrink-0 bg-gray-50/50">
          <div className="flex items-center gap-3">
            <img src="/logo.jpg" alt="Maraki Logo" className="w-10 h-10 rounded-full object-cover border border-amber-300 shadow-sm" />
            <div>
              <p className="eyebrow">{shiftSession.shiftType === 'day' ? 'የቀን' : 'የማታ'} ሺፍት ማጠቃለያ</p>
              <h2 className="text-xl sm:text-2xl font-bold text-gray-900">የሺፍት ማጠቃለያ መዝገብ (Shift Reconciliation)</h2>
            </div>
          </div>
          <button className="icon-button" onClick={onClose}>
            <X className="w-5 h-5 text-gray-400 hover:text-gray-700" />
          </button>
        </div>

        {/* Top Visual Progress Indicator Bar (Fixed) */}
        <div className="px-6 sm:px-8 pt-4 shrink-0 bg-white">
          <div className="progress-steps">
            {[1, 2, 3, 4, 5].map((s) => (
              <span key={s} className={s <= step ? 'done' : ''}>
                {s < step ? <Check className="w-3.5 h-3.5" /> : s}
              </span>
            ))}
          </div>
          <div className="progress-line relative overflow-hidden">
            <i style={{ width: `${progressPercent}%` }} />
          </div>
          <div className="flex justify-between text-[10px] text-gray-500 font-bold mt-2 px-2">
            <span className={step === 1 ? 'text-primary font-bold' : ''}>1. ሽያጭ</span>
            <span className={step === 2 ? 'text-primary font-bold' : ''}>2. የብርጭቆ ቆጠራ</span>
            <span className={step === 3 ? 'text-primary font-bold' : ''}>3. ወጪዎች</span>
            <span className={step === 4 ? 'text-primary font-bold' : ''}>4. የተሰበሰበ አዳሪ</span>
            <span className={step === 5 ? 'text-primary font-bold' : ''}>5. ርክክብ እና ቁልፍ</span>
          </div>
        </div>

        {/* Wizard Step Body (Scrollable) */}
        <div className="wizard-content px-6 sm:px-8 py-5 flex-1 overflow-y-auto">
          {/* STEP 1: Shift Sales Summary */}
          {step === 1 && (
            <div>
              <p className="eyebrow text-xs font-bold text-gray-400">ደረጃ 1 ከ 5</p>
              <h3 className="text-xl font-bold text-gray-900">የሺፍት ሽያጭ ማጠቃለያ (Sales Summary)</h3>
              <p className="muted text-xs">በዚህ ሺፍት የተከናወኑ የፋይናንስ ክፍያዎች ዝርዝር።</p>

              {/* Metrics Grid */}
              <div className="grid grid-cols-3 md:grid-cols-5 gap-2 mb-6">
                <div className="metric p-3 bg-gray-50 rounded-xl border border-gray-200">
                  <span className="text-[10px] text-gray-500 font-medium">ጠቅላላ ገቢ</span>
                  <strong className="text-base text-gray-900 font-bold block mt-1">{grossRevenue.toFixed(0)} <small className="text-[10px]">ETB</small></strong>
                </div>
                <div className="metric p-3 bg-emerald-50 rounded-xl border border-emerald-100">
                  <span className="text-[10px] text-emerald-700 font-medium">ጥሬ ገንዘብ (Cash)</span>
                  <strong className="text-base text-emerald-800 font-bold block mt-1">{cashSales.toFixed(0)} <small className="text-[10px]">ETB</small></strong>
                </div>
                <div className="metric p-3 bg-blue-50 rounded-xl border border-blue-100">
                  <span className="text-[10px] text-blue-700 font-medium">ባንክ ማስተላለፍ</span>
                  <strong className="text-base text-blue-800 font-bold block mt-1">{transferSales.toFixed(0)} <small className="text-[10px]">ETB</small></strong>
                </div>
                <div className="metric p-3 bg-purple-50 rounded-xl border border-purple-100">
                  <span className="text-[10px] text-purple-700 font-medium">አዳሪ (Adari)</span>
                  <strong className="text-base text-purple-800 font-bold block mt-1">{creditSales.toFixed(0)} <small className="text-[10px]">ETB</small></strong>
                </div>
                <div className="metric p-3 bg-amber-50 rounded-xl border border-amber-100">
                  <span className="text-[10px] text-amber-700 font-medium">ዴሊቨሪ</span>
                  <strong className="text-base text-amber-800 font-bold block mt-1">{deliverySales.toFixed(0)} <small className="text-[10px]">ETB</small></strong>
                </div>
              </div>

              {/* Itemized Sales Table */}
              <div className="border border-gray-200 rounded-xl overflow-hidden max-h-52 overflow-y-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-gray-50 border-b border-gray-200 text-gray-500 font-semibold">
                    <tr>
                      <th className="p-2.5">ሰዓት</th>
                      <th className="p-2.5">የታዘዙ እቃዎች</th>
                      <th className="p-2.5">የክፍያ አይነት</th>
                      <th className="p-2.5 text-right">ዋጋ (ETB)</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100">
                    {orders.length === 0 ? (
                      <tr>
                        <td colSpan={4} className="p-4 text-center text-gray-400">በዚህ ሺፍት የተመዘገበ ሽያጭ የለም።</td>
                      </tr>
                    ) : (
                      orders.map((o) => (
                        <tr key={o.id} className="hover:bg-gray-50">
                          <td className="p-2.5 text-gray-500 font-mono text-[11px]">
                            {new Date(o.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </td>
                          <td className="p-2.5 font-medium text-gray-800">
                            {o.items.map(i => `${i.quantity}x ${i.name}`).join(', ')}
                          </td>
                          <td className="p-2.5">
                            <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                              o.paymentMethod === 'Cash' ? 'bg-emerald-100 text-emerald-800' :
                              o.paymentMethod === 'Transfer' ? 'bg-blue-100 text-blue-800' :
                              o.paymentMethod === 'Credit' ? 'bg-purple-100 text-purple-800' : 'bg-gray-100 text-gray-700'
                            }`}>
                              {o.paymentMethod === 'Cash' ? 'ጥሬ ገንዘብ' : o.paymentMethod === 'Transfer' ? 'ባንክ' : o.paymentMethod === 'Credit' ? 'ያልተከፈለ አዳሪ' : o.paymentMethod}
                            </span>
                          </td>
                          <td className="p-2.5 text-right font-bold text-gray-900">{o.total.toFixed(0)} ETB</td>
                        </tr>
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* STEP 2: Cup and Container Inventory Count (Strict Blind Cross-check) */}
          {step === 2 && (
            <div>
              <p className="eyebrow text-xs font-bold text-gray-400">ደረጃ 2 ከ 5</p>
              <h3 className="text-xl font-bold text-gray-900">የብርጭቆ ቆጠራ እና ማረጋገጫ (Cup Count Verification)</h3>
              <p className="muted text-xs">በእጅ በአካል የተረፈውን የብርጭቆ ብዛት ያስገቡ። ቆጠራው ከPOS ሽያጭ ጋር ካልተጣጣመ ወደ ቀጣይ ደረጃ ማለፍ አይቻልም።</p>

              <div className="inventory-form grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
                <div>
                  <label className="text-xs font-bold text-gray-700 block mb-1">የመጀመሪያ ርክክብ</label>
                  <input
                    type="number"
                    min="0"
                    value={openingCups}
                    onFocus={(e) => e.target.select()}
                    onChange={(e) => setOpeningCups(e.target.value.replace(/^0+(?=\d)/, ''))}
                    className="w-full border border-gray-300 rounded-xl p-2.5 text-base font-bold bg-gray-50 outline-primary"
                  />
                  <span className="text-[10px] text-gray-400 mt-1 block">የመጀመሪያ ብርጭቆ</span>
                </div>
                <div>
                  <label className="text-xs font-bold text-gray-700 block mb-1">በሺፍት መሃል የተጨመረ</label>
                  <input
                    type="number"
                    min="0"
                    placeholder="0"
                    value={addedCups}
                    onFocus={(e) => e.target.select()}
                    onChange={(e) => setAddedCups(e.target.value.replace(/^0+(?=\d)/, ''))}
                    className="w-full border border-gray-300 rounded-xl p-2.5 text-base font-bold outline-primary"
                  />
                  <span className="text-[10px] text-gray-400 mt-1 block">በሺፍት መሃል የመጣ</span>
                </div>
                <div>
                  <label className="text-xs font-bold text-gray-900 block mb-1">
                    በእጅ የተረፈ (Physical Leftover) <span className="text-red-500">*ግዴታ</span>
                  </label>
                  <input
                    type="number"
                    min="0"
                    placeholder="የተረፈ ብርጭቆ ያስገቡ..."
                    value={leftoverCups}
                    onFocus={(e) => e.target.select()}
                    onChange={(e) => setLeftoverCups(e.target.value.replace(/^0+(?=\d)/, ''))}
                    className="w-full border-2 border-primary rounded-xl p-2.5 text-base font-black outline-primary bg-white shadow-sm"
                  />
                  <span className="text-[10px] text-primary font-semibold mt-1 block">አሁን በእጅ የቆጠሩትን ያስገቡ</span>
                </div>
              </div>

              {/* Status & Cross-check Feedback */}
              {!isCupCountEntered ? (
                <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl flex items-center gap-3">
                  <AlertCircle className="w-5 h-5 text-amber-600 shrink-0" />
                  <div className="text-xs text-amber-900">
                    <strong className="block font-bold">እባክዎ የተረፈውን የብርጭቆ ብዛት ያስገቡ</strong>
                    <span>ቆጠራውን ሲያስገቡ ስርዓቱ ከPOS ታብሌት ሽያጭ ጋር አወዳድሮ ያረጋግጣል።</span>
                  </div>
                </div>
              ) : isCupCountMatched ? (
                <div className="space-y-3">
                  <div className="p-4 bg-emerald-50 border border-emerald-300 rounded-xl flex items-center justify-between">
                    <div>
                      <span className="text-xs font-bold text-emerald-900 block flex items-center gap-1.5">
                        <Check className="w-4 h-4 text-emerald-600" /> ልክ ተጣጥሟል! (0 ልዩነት - Perfectly Matched)
                      </span>
                      <em className="text-[11px] text-emerald-700 not-italic block mt-1">
                        የተሰላ ሽያጭ = (የመጀመሪያ {openingCups} + የተጨመረ {addedCups}) − የተረፈ {numLeftover} = <strong>{calculatedCupsSold} ብርጭቆዎች</strong>
                      </em>
                    </div>
                    <div className="text-right">
                      <strong className="text-2xl font-black text-emerald-800">{calculatedCupsSold} <small className="text-xs font-normal">ብርጭቆዎች</small></strong>
                      <span className="text-[10px] text-emerald-600 block">በPOS የተሸጠ: {cupsSold}</span>
                    </div>
                  </div>
                  <div className="p-3 bg-emerald-100/60 rounded-lg text-xs font-bold text-emerald-900 flex items-center gap-2">
                    <Check className="w-4 h-4 text-emerald-700" />
                    <span>የብርጭቆ ቆጠራው ሙሉ በሙሉ ትክክል ነው።</span>
                  </div>
                </div>
              ) : (
                <div className="space-y-3">
                  {/* Calculation Discrepancy Card */}
                  <div className="p-4 bg-red-50 border-2 border-red-300 rounded-xl">
                    <div className="flex items-start justify-between">
                      <div>
                        <span className="text-xs font-bold text-red-900 flex items-center gap-1.5">
                          <AlertCircle className="w-4 h-4 text-red-600" /> የብርጭቆ ልዩነት ተገኝቷል!
                        </span>
                        <div className="mt-2 text-xs text-gray-700 space-y-1">
                          <div>
                            • የቀመር ስሌት: (የመጀመሪያ {openingCups} + የተጨመረ {addedCups}) − የተረፈ {numLeftover} = <strong className="text-red-700">{calculatedCupsSold} ብርጭቆ</strong>
                          </div>
                          <div>
                            • በPOS ታብሌት የተሸጠ: <strong className="text-gray-900">{cupsSold} ብርጭቆ</strong>
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <span className="px-3 py-1 bg-red-100 text-red-800 text-xs font-black rounded-full inline-block">
                          {cupsVariance! > 0 ? `+${cupsVariance} ብርጭቆ ትርፍ` : `${cupsVariance} ብርጭቆ ጉድለት`}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg text-xs text-amber-900 flex items-center gap-2">
                    <AlertCircle className="w-4 h-4 text-amber-700 shrink-0" />
                    <span>
                      የብርጭቆ ልዩነት ስላለ ወደ ቀጣይ ደረጃ ማለፍ አይቻልም! እባክዎ በእጅ ያለውን የብርጭቆ ቆጠራ አስተካክለው ያስገቡ።
                    </span>
                  </div>
                </div>
              )}

              {/* PART B: Food Production vs Waiter Sales Cross-Check */}
              <div className="mt-8 pt-6 border-t border-gray-200">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <Utensils className="w-5 h-5 text-amber-600" />
                    <h4 className="text-lg font-bold text-gray-900">የኩሽና ምግብ ርክክብ እና ማረጋገጫ (Kitchen Food Cross-Check)</h4>
                  </div>
                  <span className="text-xs px-2.5 py-1 bg-gray-100 rounded-full font-bold text-gray-700">
                    {shiftRouteName === 'Day shift' ? 'የቀን ሺፍት ቲኬቶች' : 'የማታ ሺፍት ቲኬቶች'}
                  </span>
                </div>
                <p className="muted text-xs mb-4">
                  ኩሽና ያዘጋጀው የምግብ ብዛት ከPOS ታብሌት ላይ ከተመዘገቡት የምግብ ማዘዣዎች ጋር ይነጻጸራል። ያልተመዘገበ ክፍተት ካለ ሺፍቱን ማጠቃለል አይቻልም።
                </p>

                {/* Metrics Grid */}
                <div className="grid grid-cols-3 gap-3 mb-4">
                  <div className="p-3 bg-amber-50/60 border border-amber-200 rounded-xl text-center">
                    <span className="text-[11px] font-bold text-amber-800 block">👩‍🍳 ኩሽና ያዘጋጀው</span>
                    <strong className="text-2xl font-black text-amber-900">{totalKitchenFoodCooked}</strong>
                    <small className="text-[10px] text-amber-700 block">ምግቦች (Cooked)</small>
                  </div>
                  <div className="p-3 bg-blue-50/60 border border-blue-200 rounded-xl text-center">
                    <span className="text-[11px] font-bold text-blue-800 block">📱 ዌተር ያስመዘገበው</span>
                    <strong className="text-2xl font-black text-blue-900">{totalWaiterFoodSold}</strong>
                    <small className="text-[10px] text-blue-700 block">የተሸጡ ምግቦች (Sold)</small>
                  </div>
                  <div className={`p-3 border rounded-xl text-center ${
                    foodVariance === 0 ? 'bg-emerald-50 border-emerald-300' :
                    foodVariance < 0 ? 'bg-red-50 border-red-300' : 'bg-purple-50 border-purple-300'
                  }`}>
                    <span className="text-[11px] font-bold block text-gray-700">⚖️ ልዩነት (Variance)</span>
                    <strong className={`text-2xl font-black ${
                      foodVariance === 0 ? 'text-emerald-800' :
                      foodVariance < 0 ? 'text-red-700' : 'text-purple-800'
                    }`}>
                      {foodVariance > 0 ? `+${foodVariance}` : foodVariance}
                    </strong>
                    <small className="text-[10px] text-gray-600 block">
                      {foodVariance === 0 ? 'ልክ ተጣጥሟል' : foodVariance < 0 ? 'የጎደለ ምግብ' : 'ትርፍ የተመዘገበ'}
                    </small>
                  </div>
                </div>

                {/* Food Item Breakdown Table */}
                {foodItemsReconciliation.length > 0 && (
                  <div className="border border-gray-200 rounded-xl overflow-hidden mb-4 bg-white">
                    <table className="w-full text-xs">
                      <thead className="bg-gray-50 border-b border-gray-200 text-gray-600 font-bold">
                        <tr>
                          <th className="p-2.5 text-left">የምግብ አይነት</th>
                          <th className="p-2.5 text-center">ኩሽና ያዘጋጀው</th>
                          <th className="p-2.5 text-center">በታብሌት የተሸጠ</th>
                          <th className="p-2.5 text-right">ሁኔታ</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-100 font-medium">
                        {foodItemsReconciliation.map(item => (
                          <tr key={item.id} className="hover:bg-gray-50/50">
                            <td className="p-2.5 font-bold text-gray-900 flex items-center gap-1.5">
                              <span>{item.emoji}</span>
                              <span>{item.name}</span>
                            </td>
                            <td className="p-2.5 text-center font-bold text-amber-900">{item.kitchenCookedCount}</td>
                            <td className="p-2.5 text-center font-bold text-blue-900">{item.waiterSoldCount}</td>
                            <td className="p-2.5 text-right">
                              <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                                item.variance === 0 ? 'bg-emerald-100 text-emerald-800' :
                                item.variance < 0 ? 'bg-red-100 text-red-800' : 'bg-purple-100 text-purple-800'
                              }`}>
                                {item.variance === 0 ? '✓ ተጣጥሟል' : item.variance < 0 ? `${item.variance} ጎድሏል` : `+${item.variance} ትርፍ`}
                              </span>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}

                {/* Food Gate Feedback */}
                {totalKitchenFoodCooked === 0 ? (
                  <div className="p-3 bg-gray-50 border border-gray-200 rounded-xl text-xs text-gray-600 flex items-center gap-2">
                    <AlertCircle className="w-4 h-4 text-gray-400 shrink-0" />
                    <span>በዚህ ሺፍት የተላከ የኩሽና ቲኬት የለም (0 የኩሽና ማዘዣዎች)።</span>
                  </div>
                ) : isFoodCountMatched ? (
                  <div className="p-3 bg-emerald-50 border border-emerald-300 rounded-xl text-xs font-bold text-emerald-900 flex items-center gap-2">
                    <Check className="w-4 h-4 text-emerald-600 shrink-0" />
                    <span>የኩሽና ምግብ ቆጠራው ሙሉ በሙሉ ተጣጥሟል! (Food Cross-Check Passed)</span>
                  </div>
                ) : (
                  <div className="p-4 bg-red-50 border-2 border-red-300 rounded-xl space-y-2">
                    <div className="flex items-center gap-2 text-red-900 font-bold text-xs">
                      <AlertCircle className="w-4 h-4 text-red-600 shrink-0" />
                      <span>ያልተመዘገበ የምግብ ክፍተት አለ! ({Math.abs(foodVariance)} ምግቦች ይጎድላሉ)</span>
                    </div>
                    <p className="text-xs text-red-800">
                      ኩሽና ያዘጋጀው <strong>{totalKitchenFoodCooked}</strong> ምግብ ሲሆን ዌተር ያስመዘገበው <strong>{totalWaiterFoodSold}</strong> ነው። 
                      እባክዎ ያልተመዘገቡትን {Math.abs(foodVariance)} ምግቦች በPOS ታብሌቱ ላይ ያስመዝግቡ፤ ያለበለዚያ ሺፍቱን ማጠቃለል አይቻልም።
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* STEP 3: Daily Shift Expenses */}
          {step === 3 && (
            <div>
              <p className="eyebrow text-xs font-bold text-gray-400">ደረጃ 3 ከ 5</p>
              <h3 className="text-xl font-bold text-gray-900">የቀን የካሽ ሬጅስተር ወጪዎች (Daily Shift Expenses)</h3>
              <p className="muted text-xs">ከካሽ ሬጅስተር ጥሬ ገንዘብ ለሱቅ እቃዎች የወጣ ወጪ ያስመዝግቡ።</p>

              {/* Quick Add Buttons */}
              <div className="quick-add flex gap-2 mb-4">
                <button onClick={() => handleAddQuickExpense('ሎሚ', 100)} className="px-3 py-1.5 border border-dashed border-gray-300 rounded-lg text-xs hover:bg-gray-50 font-medium">
                  +100 ETB ሎሚ
                </button>
                <button onClick={() => handleAddQuickExpense('በረዶ', 200)} className="px-3 py-1.5 border border-dashed border-gray-300 rounded-lg text-xs hover:bg-gray-50 font-medium">
                  +200 ETB በረዶ
                </button>
                <button onClick={() => handleAddQuickExpense('ስኳር', 150)} className="px-3 py-1.5 border border-dashed border-gray-300 rounded-lg text-xs hover:bg-gray-50 font-medium">
                  +150 ETB ስኳር
                </button>
                <button onClick={() => handleAddQuickExpense('ላስቲክ', 50)} className="px-3 py-1.5 border border-dashed border-gray-300 rounded-lg text-xs hover:bg-gray-50 font-medium">
                  +50 ETB ላስቲክ
                </button>
              </div>

              {/* Custom Expense Input Form */}
              <form onSubmit={handleCustomExpenseAdd} className="flex gap-2 mb-4">
                <select
                  value={expenseCat}
                  onChange={(e) => setExpenseCat(e.target.value)}
                  className="border border-gray-300 rounded-lg p-2 text-xs bg-white font-medium"
                >
                  <option value="ሎሚ">ሎሚ</option>
                  <option value="በረዶ">በረዶ</option>
                  <option value="ስኳር">ስኳር</option>
                  <option value="ላስቲክ">ላስቲክ</option>
                  <option value="ትራንስፖርት">ትራንስፖርት</option>
                  <option value="ሌላ ወጪ">ሌላ ወጪ</option>
                </select>
                <input
                  placeholder="የወጪ ዝርዝር መግለጫ..."
                  value={expenseDesc}
                  onChange={(e) => setExpenseDesc(e.target.value)}
                  className="border border-gray-300 rounded-lg p-2 text-xs flex-1 outline-primary"
                />
                <input
                  type="number"
                  placeholder="መጠን (ETB)"
                  value={expenseAmount}
                  onFocus={(e) => e.target.select()}
                  onChange={(e) => setExpenseAmount(e.target.value.replace(/^0+(?=\d)/, ''))}
                  className="border border-gray-300 rounded-lg p-2 text-xs w-28 outline-primary font-bold"
                />
                <button type="submit" className="px-4 py-2 bg-gray-900 text-white rounded-lg text-xs font-bold hover:bg-gray-800">
                  <Plus className="w-3.5 h-3.5 inline mr-1" /> ጨምር
                </button>
              </form>

              {/* Itemized Expense List */}
              <div className="border border-gray-200 rounded-xl p-3 bg-gray-50 max-h-44 overflow-y-auto">
                {expenses.length === 0 ? (
                  <p className="text-xs text-gray-400 text-center py-3">ምንም የተመዘገበ ወጪ የለም።</p>
                ) : (
                  <div className="divide-y divide-gray-200">
                    {expenses.map((exp) => (
                      <div key={exp.id} className="py-2 flex items-center justify-between">
                        <div>
                          <strong className="text-xs font-bold text-gray-800">{exp.category}</strong>
                          <span className="text-[11px] text-gray-500 ml-2">{exp.description}</span>
                        </div>
                        <div className="flex items-center gap-3">
                          <strong className="text-xs font-bold text-red-600">-{exp.amount.toFixed(0)} ETB</strong>
                          <button onClick={() => handleDeleteExpense(exp.id)} className="text-gray-400 hover:text-red-500">
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
                <div className="border-t border-gray-200 pt-2 mt-2 flex justify-between text-xs font-bold text-gray-900">
                  <span>ጠቅላላ የካሽ ሬጅስተር ወጪ</span>
                  <span className="text-red-600">-{totalExpenses.toFixed(0)} ETB</span>
                </div>
              </div>
            </div>
          )}

          {/* STEP 4: Pooled Pending Credit Collection */}
          {step === 4 && (
            <div>
              <p className="eyebrow text-xs font-bold text-gray-400">ደረጃ 4 ከ 5</p>
              <h3 className="text-xl font-bold text-gray-900">የቆየ የብርጭቆ አዳሪ ስብስብ (Pending Adari Collection)</h3>
              <p className="muted text-xs">ዛሬ ስንት ብርጭቆ ዋጋ ከአዳሪ ደንበኞች ተሰብስቧል? ማንኛውም ቁጥር ያስገቡ — ቀሪው ለቀጣይ ሺፍት ይቀራል።</p>

              {/* Total Pending Pool */}
              <div className="p-4 bg-gray-50 border border-gray-200 rounded-xl mb-5">
                <div className="flex items-center justify-between mb-3">
                  <div>
                    <span className="text-[10px] font-bold text-gray-500 uppercase tracking-wider block mb-1">ጠቅላላ ያልተከፈሉ ብርጭቆዎች</span>
                    <strong className="text-2xl font-black text-gray-900">{totalPendingCups} ብርጭቆ</strong>
                    <span className="text-xs text-gray-500 ml-2">= {totalPendingETB.toFixed(0)} ETB</span>
                  </div>
                  <div className="text-right">
                    <span className="text-[10px] font-bold text-gray-500 uppercase tracking-wider block mb-1">ቀሪ አዳሪ</span>
                    <strong className="text-xl font-extrabold text-gray-700">{remainingPendingCups} ብርጭቆ</strong>
                    <span className="text-xs text-gray-400 ml-1">= {(remainingPendingCups * PRICE_PER_CUP).toFixed(0)} ETB</span>
                  </div>
                </div>

                {/* Cups collected input */}
                <label className="block">
                  <span className="text-xs font-bold text-gray-700 block mb-2">ዛሬ ስንት ብርጭቆ ዋጋ ተሰበሰበ?</span>
                  <div className="flex items-center gap-3">
                    <button
                      type="button"
                      onClick={() => setCupsCollectedToday(String(Math.max(0, numCupsCollected - 1)))}
                      className="w-10 h-10 rounded-xl border border-gray-300 bg-white text-gray-700 font-bold text-lg flex items-center justify-center hover:bg-gray-50"
                    >−</button>
                    <input
                      type="number"
                      min="0"
                      max={totalPendingCups}
                      placeholder="0"
                      value={cupsCollectedToday}
                      onFocus={(e) => e.target.select()}
                      onChange={(e) => {
                        const raw = e.target.value.replace(/^0+(?=\d)/, '');
                        const num = Number(raw) || 0;
                        const capped = Math.min(totalPendingCups, Math.max(0, num));
                        setCupsCollectedToday(raw === '' ? '' : String(capped));
                      }}
                      className="w-24 text-center border border-gray-300 rounded-xl p-2 text-xl font-black outline-none focus:border-primary"
                    />
                    <button
                      type="button"
                      onClick={() => setCupsCollectedToday(String(Math.min(totalPendingCups, numCupsCollected + 1)))}
                      className="w-10 h-10 rounded-xl border border-gray-300 bg-white text-gray-700 font-bold text-lg flex items-center justify-center hover:bg-gray-50"
                    >+</button>
                    <span className="text-xs text-gray-500">ብርጭቆ</span>
                    {totalPendingCups > 0 && (
                      <button
                        type="button"
                        onClick={() => setCupsCollectedToday(String(totalPendingCups))}
                        className="ml-auto px-3 py-1.5 border border-gray-300 rounded-lg text-xs font-bold text-gray-700 hover:bg-gray-50"
                      >ሁሉም ({totalPendingCups})</button>
                    )}
                  </div>
                </label>
              </div>

              {/* Quick-add shortcuts */}
              {totalPendingCups > 0 && (
                <div className="flex gap-2 flex-wrap mb-4">
                  {[1, 2, 3, 5].filter(n => n <= totalPendingCups).map(n => (
                    <button
                      key={n}
                      type="button"
                      onClick={() => setCupsCollectedToday(String(Math.min(totalPendingCups, numCupsCollected + n)))}
                      className="px-3 py-1.5 border border-dashed border-gray-300 rounded-lg text-xs font-bold text-gray-600 hover:bg-gray-50"
                    >+{n} ብርጭቆ</button>
                  ))}
                </div>
              )}

              {/* Collected Cash Callout */}
              <div className="p-3 bg-gray-50 border border-gray-200 rounded-xl flex items-center justify-between">
                <div>
                  <span className="text-[10px] font-bold text-gray-500 uppercase tracking-wider block">ዛሬ የተሰበሰበ አዳሪ</span>
                  <span className="text-xs text-gray-600">{totalRecoveredCups} ብርጭቆ × 170 ETB</span>
                </div>
                <strong className="text-xl font-extrabold text-gray-900">+{totalRecoveredDebts.toFixed(0)} ETB</strong>
              </div>
            </div>
          )}

          {/* STEP 5: Final Cash Handover and Security Lock */}
          {step === 5 && (
            <div className="space-y-4">
              <div>
                <p className="eyebrow text-xs font-bold text-gray-400">ደረጃ 5 ከ 5</p>
                <h3 className="text-xl font-black text-gray-900">የመጨረሻ የገንዘብ ርክክብ እና ቁልፍ (Cash Handover)</h3>
              </div>

              {/* Bold Attention Banner */}
              <div className="p-3.5 bg-gradient-to-r from-amber-500/15 via-amber-500/5 to-transparent border-l-4 border-amber-500 rounded-r-xl flex items-center gap-3">
                <AlertCircle className="w-5 h-5 text-amber-700 shrink-0" />
                <strong className="text-xs sm:text-sm font-black text-amber-950 leading-snug">
                  የካሽ ሬጅስተሩን ከመቆለፍዎ በፊት የገንዘብ ርክክብ ቀመሩን ያረጋግጡ።
                </strong>
              </div>

              {/* Attractive & Bold Net Cash Handover Formula Card */}
              <div className="border-2 border-emerald-500/80 bg-gradient-to-b from-emerald-50/70 via-emerald-50/30 to-white rounded-2xl p-4 sm:p-5 shadow-sm space-y-3">
                {/* Card Header */}
                <div className="flex items-center justify-between border-b border-emerald-200/80 pb-3">
                  <div className="flex items-center gap-2.5">
                    <div className="w-9 h-9 rounded-xl bg-emerald-700 text-white flex items-center justify-center shadow-md font-bold">
                      <Wallet className="w-4 h-4" />
                    </div>
                    <div>
                      <span className="text-[10px] font-black uppercase tracking-wider text-emerald-800 block">የሂሳብ ቀመር ስሌት</span>
                      <strong className="text-sm sm:text-base font-black text-gray-900">
                        የገንዘብ ርክክብ ቀመር (Net Cash Handover)
                      </strong>
                    </div>
                  </div>
                  <span className="px-3 py-1 bg-emerald-100/80 text-emerald-900 rounded-full text-xs font-black border border-emerald-300">
                    {shiftSession.shiftType === 'day' ? '☀ የቀን ሺፍት' : '☾ የማታ ሺፍት'}
                  </span>
                </div>

                {/* Line 1: Cash Sales */}
                <div className="flex items-center justify-between p-3 rounded-xl bg-white border border-gray-200/80 shadow-2xs hover:border-emerald-300 transition-colors">
                  <div className="flex items-center gap-2.5">
                    <span className="w-6 h-6 rounded-full bg-emerald-100 text-emerald-800 flex items-center justify-center text-xs font-black">
                      +
                    </span>
                    <strong className="text-xs sm:text-sm font-black text-gray-900">
                      የዛሬ የጥሬ ገንዘብ ሽያጭ (Cash Sales):
                    </strong>
                  </div>
                  <strong className="text-xs sm:text-sm font-black text-emerald-700 font-mono bg-emerald-50 px-3 py-1 rounded-lg border border-emerald-200">
                    +{cashSales.toFixed(0)} ETB
                  </strong>
                </div>

                {/* Line 2: Recovered Pending Debts */}
                <div className="flex items-center justify-between p-3 rounded-xl bg-white border border-gray-200/80 shadow-2xs hover:border-blue-300 transition-colors">
                  <div className="flex items-center gap-2.5">
                    <span className="w-6 h-6 rounded-full bg-blue-100 text-blue-800 flex items-center justify-center text-xs font-black">
                      +
                    </span>
                    <strong className="text-xs sm:text-sm font-black text-gray-900">
                      + የተሰበሰበ የቆየ አዳሪ (ደረጃ 4):
                    </strong>
                  </div>
                  <strong className="text-xs sm:text-sm font-black text-blue-700 font-mono bg-blue-50 px-3 py-1 rounded-lg border border-blue-200">
                    +{totalRecoveredDebts.toFixed(0)} ETB <span className="text-[11px] font-bold opacity-80 font-sans">({totalRecoveredCups} ብርጭቆ)</span>
                  </strong>
                </div>

                {/* Line 3: Daily Register Expenses */}
                <div className="flex items-center justify-between p-3 rounded-xl bg-white border border-gray-200/80 shadow-2xs hover:border-rose-300 transition-colors">
                  <div className="flex items-center gap-2.5">
                    <span className="w-6 h-6 rounded-full bg-rose-100 text-rose-800 flex items-center justify-center text-xs font-black">
                      −
                    </span>
                    <strong className="text-xs sm:text-sm font-black text-gray-900">
                      − የዛሬ የሬጅስተር ወጪዎች (ደረጃ 3):
                    </strong>
                  </div>
                  <strong className="text-xs sm:text-sm font-black text-rose-600 font-mono bg-rose-50 px-3 py-1 rounded-lg border border-rose-200">
                    −{totalExpenses.toFixed(0)} ETB
                  </strong>
                </div>

                {/* Grand Total Callout Box */}
                <div className="p-4 sm:p-5 rounded-2xl bg-gradient-to-br from-emerald-800 via-emerald-900 to-teal-950 text-white shadow-xl flex flex-col sm:flex-row sm:items-center justify-between gap-4 border border-emerald-600 mt-2">
                  <div>
                    <div className="flex items-center gap-1.5 text-emerald-300 text-xs font-bold mb-1">
                      <ShieldCheck className="w-4 h-4 text-emerald-300 shrink-0" />
                      <span className="font-extrabold uppercase tracking-wide text-[10px]">ለባለቤቱ የሚሰጥ ጥሬ ገንዘብ</span>
                    </div>
                    <strong className="text-base sm:text-lg font-black tracking-tight text-white block">
                      ለባለቤቱ የሚረከበው የተጣራ ገንዘብ
                    </strong>
                    <strong className="text-xs font-bold text-emerald-200 block mt-1 leading-relaxed">
                      ተጣራ ገንዘብ = የጥሬ ገንዘብ ሽያጭ + የተሰበሰበ አዳሪ − ወጪዎች
                    </strong>
                  </div>
                  <div className="text-left sm:text-right bg-black/30 px-5 py-3 rounded-xl border border-white/15 shrink-0 shadow-inner">
                    <span className="text-[10px] uppercase tracking-wider text-emerald-300 font-black block">የተጣራ ጥሬ ገንዘብ</span>
                    <strong className="text-3xl sm:text-4xl font-black text-white font-mono tracking-tight">
                      {netCashToOwner.toFixed(0)} <span className="text-sm font-bold text-emerald-200">ETB</span>
                    </strong>
                  </div>
                </div>
              </div>

              {/* Shift Notes Textarea */}
              <label className="block">
                <span className="text-xs font-black text-gray-800 block mb-1.5">የሺፍት ማስታወሻ (አማራጭ)</span>
                <textarea
                  value={shiftNotes}
                  onChange={(e) => setShiftNotes(e.target.value)}
                  placeholder="ለባለቤቱ ወይም ለሚቀጥለው ሺፍት ማስታወሻ ይጻፉ..."
                  className="w-full border border-gray-300 rounded-xl p-3 text-xs font-semibold outline-primary h-16 resize-none shadow-2xs"
                />
              </label>

              {/* Submit Button */}
              <button
                onClick={() => setShowPinModal(true)}
                className="w-full bg-gradient-to-r from-emerald-700 to-teal-800 hover:from-emerald-800 hover:to-teal-900 text-white font-black py-4 rounded-xl shadow-lg flex items-center justify-center gap-2.5 text-sm sm:text-base transition-all active:scale-[0.99] cursor-pointer"
              >
                <Lock className="w-4 h-4" />
                <span>በ PIN አረጋግጥ እና ሺፍት ዝጋ</span>
              </button>
            </div>
          )}
        </div>

        {/* Wizard Footer Navigation Buttons (Fixed at Bottom) */}
        <div className="modal-footer border-t border-gray-100 px-6 sm:px-8 py-4 flex justify-between shrink-0 bg-gray-50/70">
          <button
            onClick={() => step === 1 ? onClose() : setStep(step - 1)}
            className="outline-button px-5 py-2.5 rounded-xl text-xs font-bold text-gray-600 border-gray-300 hover:bg-gray-100 flex items-center gap-1.5 cursor-pointer"
          >
            <ArrowLeft className="w-4 h-4" /> {step === 1 ? 'ሰርዝ (Cancel)' : 'ወደ ኋላ (Previous)'}
          </button>

          {step < 5 && (
            <button
              onClick={() => {
                if (step === 2 && !canProceedStep2) return;
                setStep(step + 1);
              }}
              disabled={step === 2 && !canProceedStep2}
              className={`px-6 py-2.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 shadow-md ${
                step === 2 && !canProceedStep2
                  ? 'bg-gray-300 text-gray-500 cursor-not-allowed shadow-none'
                  : 'text-white bg-primary hover:bg-primary/90 cursor-pointer'
              }`}
            >
              {step === 2 && !canProceedStep2
                ? (leftoverCups === '' ? 'ቆጠራውን ያስገቡ' : 'ልዩነቱን ያስተካክሉ (Fix Discrepancy)')
                : 'ቀጣይ (Next)'}
              <ArrowRight className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>

      {/* 4-Digit Security Keypad Modal */}
      {showPinModal && (
        <PinPadModal
          onCancel={() => setShowPinModal(false)}
          onConfirm={handleFinalSubmit}
          title="የካሸር PIN ማረጋገጫ"
          subtitle="ሺፍቱን ለመዝጋት 4-ዲጂት የካሸር PIN ያስገቡ"
        />
      )}
    </div>
  );
}
