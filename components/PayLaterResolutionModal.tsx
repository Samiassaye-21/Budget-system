'use client';

import React, { useState } from 'react';
import {
  X, Check, AlertTriangle, ArrowRight, ArrowLeft,
  Wallet, Smartphone, ReceiptText, Clock, User, ChevronRight, Sparkles
} from 'lucide-react';
import { Order, PaymentMethod, CustomerDebt } from '../types/pos';

export type PayLaterResolutionType = 'Cash' | 'Transfer' | 'Credit';

export interface OrderResolution {
  orderId: string;
  resolvedMethod: PayLaterResolutionType;
  customerName?: string;
  notes?: string;
}

interface PayLaterResolutionModalProps {
  shiftId: string;
  payLaterOrders: Order[];
  onClose: () => void;
  onConfirmResolutions: (
    updatedOrders: Order[],
    newDebts: CustomerDebt[]
  ) => void;
}

export function PayLaterResolutionModal({
  shiftId,
  payLaterOrders,
  onClose,
  onConfirmResolutions,
}: PayLaterResolutionModalProps) {
  // Map of orderId -> resolution
  const [resolutions, setResolutions] = useState<Record<string, { method: PayLaterResolutionType; customerName: string; notes: string }>>(() => {
    const initial: Record<string, { method: PayLaterResolutionType; customerName: string; notes: string }> = {};
    payLaterOrders.forEach(o => {
      // By default empty method so it MUST be explicitly chosen
      initial[o.id] = {
        method: '' as PayLaterResolutionType,
        customerName: o.notes || '',
        notes: o.notes || '',
      };
    });
    return initial;
  });

  const [currentIndex, setCurrentIndex] = useState<number>(0);

  const currentOrder = payLaterOrders[currentIndex] || payLaterOrders[0];
  const currentResolution = currentOrder ? resolutions[currentOrder.id] : null;

  // Counts of resolved items
  const resolvedCount = Object.values(resolutions).filter(r => r.method !== ('' as any)).length;
  const totalCount = payLaterOrders.length;
  const isAllResolved = resolvedCount === totalCount && totalCount > 0;

  // Summary totals for visual clarity
  const cashCount = Object.values(resolutions).filter(r => r.method === 'Cash').length;
  const transferCount = Object.values(resolutions).filter(r => r.method === 'Transfer').length;
  const pendingCount = Object.values(resolutions).filter(r => r.method === 'Credit').length;

  const handleSelectMethod = (orderId: string, method: PayLaterResolutionType) => {
    setResolutions(prev => ({
      ...prev,
      [orderId]: {
        ...prev[orderId],
        method,
      }
    }));
  };

  const handleUpdateCustomerName = (orderId: string, name: string) => {
    setResolutions(prev => ({
      ...prev,
      [orderId]: {
        ...prev[orderId],
        customerName: name,
      }
    }));
  };

  const handleFinalSubmit = () => {
    if (!isAllResolved) return;

    const newDebts: CustomerDebt[] = [];
    const updatedOrders = payLaterOrders.map(order => {
      const res = resolutions[order.id];
      const newMethod: PaymentMethod = res.method === 'Credit' ? 'Credit' : res.method;

      // If resolved as Credit (Pending Payment), create a customer debt record
      if (res.method === 'Credit') {
        const juiceCupsCount = order.items
          .filter(i => i.category === 'Juice')
          .reduce((sum, i) => sum + i.quantity, 0);

        const newDebt: CustomerDebt = {
          id: `deb-paylater-${Date.now()}-${order.id}`,
          customerName: res.customerName.trim() || order.notes?.trim() || `ያልታወቀ ደንበኛ (ትዕዛዝ #${order.id.slice(-4)})`,
          note: `Pay later ትዕዛዝ: ${order.items.map(i => `${i.quantity}x ${i.name}`).join(', ')}`,
          cupCount: juiceCupsCount || 1,
          pricePerCup: 170,
          amount: order.total,
          isRecovered: false,
          shiftIdCreated: shiftId,
          createdAt: new Date().toISOString()
        };
        newDebts.push(newDebt);
      }

      return {
        ...order,
        paymentMethod: newMethod,
        notes: res.customerName
          ? (order.notes ? `${order.notes} | ደንበኛ: ${res.customerName}` : `ደንበኛ: ${res.customerName}`)
          : order.notes
      };
    });

    onConfirmResolutions(updatedOrders, newDebts);
  };

  return (
    <div className="modal-backdrop z-50 overflow-y-auto py-6">
      <div className="reconcile-modal max-w-2xl w-full bg-white rounded-2xl shadow-2xl overflow-hidden border border-gray-200 flex flex-col max-h-[92vh] my-auto">
        
        {/* Header (Fixed) */}
        <div className="modal-top border-b border-gray-100 bg-amber-50/70 p-4 sm:p-5 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-amber-500 text-white flex items-center justify-center shadow-md font-bold">
              <ReceiptText className="w-5 h-5" />
            </div>
            <div>
              <span className="text-[10px] font-black uppercase tracking-wider text-amber-800">
                የግዴታ ማረጋገጫ (MANDATORY RESOLUTION)
              </span>
              <h2 className="text-xl font-extrabold text-gray-900 leading-tight">
                የPay Later ትዕዛዞች ማረጋገጫ
              </h2>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full flex items-center justify-center text-gray-400 hover:text-gray-700 hover:bg-gray-100"
            title="ዝጋ"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Informational Alert Banner */}
        <div className="bg-amber-100/60 px-6 py-3 border-b border-amber-200/80 flex items-center gap-2.5 text-xs text-amber-900 font-medium">
          <AlertTriangle className="w-4 h-4 text-amber-700 shrink-0" />
          <span>
            ሺፍቱን ከመዝጋትዎ በፊት <strong>{totalCount}</strong> የPay Later ትዕዛዞችን ወደ <strong>ጥሬ ገንዘብ (Cash)</strong>፣ <strong>ባንክ (Transfer)</strong> ወይም <strong>ያልተከፈለ ብድር (Pending Debt)</strong> መመደብ ግዴታ ነው።
          </span>
        </div>

        {/* Order Navigation Pills */}
        <div className="px-6 pt-4 pb-2 border-b border-gray-100 bg-gray-50 flex items-center gap-2 overflow-x-auto">
          {payLaterOrders.map((order, idx) => {
            const res = resolutions[order.id];
            const isResolved = Boolean(res?.method);
            const isCurrent = idx === currentIndex;

            return (
              <button
                key={order.id}
                type="button"
                onClick={() => setCurrentIndex(idx)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1.5 shrink-0 ${
                  isCurrent
                    ? 'bg-gray-900 text-white shadow-sm'
                    : isResolved
                    ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                    : 'bg-white text-gray-700 border border-gray-300 hover:bg-gray-100'
                }`}
              >
                {isResolved ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Clock className="w-3.5 h-3.5" />}
                <span>ትዕዛዝ #{idx + 1}</span>
                <span className="text-[10px] opacity-75 font-normal">({order.total.toFixed(0)} ETB)</span>
              </button>
            );
          })}
        </div>

        {/* Active Order Card Body (Scrollable) */}
        {currentOrder && (
          <div className="p-5 sm:p-6 overflow-y-auto flex-1">
            <div className="bg-white border border-gray-200 rounded-2xl p-4 sm:p-5 shadow-sm mb-4">
              <div className="flex items-start justify-between border-b border-gray-100 pb-3 mb-3">
                <div>
                  <span className="text-[11px] font-bold text-gray-400 uppercase tracking-wider">
                    ትዕዛዝ {currentIndex + 1} ከ {totalCount}
                  </span>
                  <h3 className="text-base font-black text-gray-900 flex items-center gap-2 mt-0.5">
                    <Clock className="w-4 h-4 text-gray-500" />
                    {new Date(currentOrder.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} የተዘገበ ትዕዛዝ
                  </h3>
                </div>
                <div className="text-right">
                  <span className="text-[10px] text-gray-400 uppercase font-bold block">ጠቅላላ ክፍያ</span>
                  <strong className="text-2xl font-black text-primary">
                    {currentOrder.total.toFixed(0)} <small className="text-xs text-gray-500 font-normal">ETB</small>
                  </strong>
                </div>
              </div>

              {/* Items in this order */}
              <div className="space-y-1.5 mb-3 bg-gray-50 p-3 rounded-xl">
                <span className="text-[10px] font-bold text-gray-400 uppercase block mb-1">የታዘዙ እቃዎች (Ordered Items):</span>
                {currentOrder.items.map((item, i) => (
                  <div key={i} className="flex justify-between text-xs font-semibold text-gray-800">
                    <span>
                      {item.quantity}x {item.name}
                    </span>
                    <span className="text-gray-500 font-mono">{(item.price * item.quantity).toFixed(0)} ETB</span>
                  </div>
                ))}
                {currentOrder.notes && (
                  <div className="pt-2 border-t border-gray-200 text-[11px] text-gray-500 italic">
                    ማስታወሻ: &ldquo;{currentOrder.notes}&rdquo;
                  </div>
                )}
              </div>

              {/* Resolution Choice Section */}
              <div>
                <label className="text-xs font-black text-gray-800 block mb-2">
                  ይህ ትዕዛዝ በምን መንገድ ተከፍሏል? (Select Settlement):
                </label>
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                  
                  {/* Choice 1: Cash */}
                  <button
                    type="button"
                    onClick={() => handleSelectMethod(currentOrder.id, 'Cash')}
                    className={`p-3 rounded-xl border text-left transition-all flex flex-col justify-between gap-1.5 cursor-pointer ${
                      currentResolution?.method === 'Cash'
                        ? 'border-emerald-600 bg-emerald-50/80 shadow-md ring-2 ring-emerald-500/20'
                        : 'border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="w-7 h-7 rounded-lg bg-emerald-100 text-emerald-800 flex items-center justify-center font-bold">
                        <Wallet className="w-3.5 h-3.5" />
                      </div>
                      {currentResolution?.method === 'Cash' && (
                        <span className="w-5 h-5 rounded-full bg-emerald-600 text-white flex items-center justify-center text-[10px]">
                          <Check className="w-3 h-3" />
                        </span>
                      )}
                    </div>
                    <div>
                      <strong className="text-xs font-extrabold text-emerald-950 block">ጥሬ ገንዘብ (Cash)</strong>
                      <span className="text-[10px] text-emerald-700 block mt-0.5">በጥሬ ገንዘብ ተከፍሏል</span>
                    </div>
                  </button>

                  {/* Choice 2: Transfer */}
                  <button
                    type="button"
                    onClick={() => handleSelectMethod(currentOrder.id, 'Transfer')}
                    className={`p-3 rounded-xl border text-left transition-all flex flex-col justify-between gap-1.5 cursor-pointer ${
                      currentResolution?.method === 'Transfer'
                        ? 'border-blue-600 bg-blue-50/80 shadow-md ring-2 ring-blue-500/20'
                        : 'border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="w-7 h-7 rounded-lg bg-blue-100 text-blue-800 flex items-center justify-center font-bold">
                        <Smartphone className="w-3.5 h-3.5" />
                      </div>
                      {currentResolution?.method === 'Transfer' && (
                        <span className="w-5 h-5 rounded-full bg-blue-600 text-white flex items-center justify-center text-[10px]">
                          <Check className="w-3 h-3" />
                        </span>
                      )}
                    </div>
                    <div>
                      <strong className="text-xs font-extrabold text-blue-950 block">ባንክ ማስተላለፍ</strong>
                      <span className="text-[10px] text-blue-700 block mt-0.5">ቴሌብር / CBE Transfer</span>
                    </div>
                  </button>

                  {/* Choice 3: Pending Credit */}
                  <button
                    type="button"
                    onClick={() => handleSelectMethod(currentOrder.id, 'Credit')}
                    className={`p-3 rounded-xl border text-left transition-all flex flex-col justify-between gap-1.5 cursor-pointer ${
                      currentResolution?.method === 'Credit'
                        ? 'border-purple-600 bg-purple-50/80 shadow-md ring-2 ring-purple-500/20'
                        : 'border-gray-200 bg-white hover:border-gray-300 hover:bg-gray-50'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="w-7 h-7 rounded-lg bg-purple-100 text-purple-800 flex items-center justify-center font-bold">
                        <ReceiptText className="w-3.5 h-3.5" />
                      </div>
                      {currentResolution?.method === 'Credit' && (
                        <span className="w-5 h-5 rounded-full bg-purple-600 text-white flex items-center justify-center text-[10px]">
                          <Check className="w-3 h-3" />
                        </span>
                      )}
                    </div>
                    <div>
                      <strong className="text-xs font-extrabold text-purple-950 block">ያልተከፈለ ብድር (Credit)</strong>
                      <span className="text-[10px] text-purple-700 block mt-0.5">አልተከፈለም - ወደ ብድር ይመዝገብ</span>
                    </div>
                  </button>

                </div>

                {/* Optional Customer Name Input if Credit/Pending */}
                {currentResolution?.method === 'Credit' && (
                  <div className="mt-3 p-3 bg-purple-50 border border-purple-200 rounded-xl animate-in fade-in">
                    <label className="text-xs font-bold text-purple-950 block mb-1 flex items-center gap-1.5">
                      <User className="w-3.5 h-3.5 text-purple-700" />
                      የተበዳሪው ደንበኛ ስም ወይም ቢሮ ቁጥር:
                    </label>
                    <input
                      type="text"
                      placeholder="ለምሳሌ: አቶ ታደሰ (ቢሮ 304) ወይም ስልክ ቁጥር"
                      value={currentResolution.customerName}
                      onChange={(e) => handleUpdateCustomerName(currentOrder.id, e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter' && isAllResolved) {
                          handleFinalSubmit();
                        }
                      }}
                      className="w-full bg-white border border-purple-300 rounded-lg p-2.5 text-xs font-semibold outline-purple-600 shadow-inner"
                    />
                    <span className="text-[10px] text-purple-600 mt-1 block">
                      ይህ ትዕዛዝ በደንበኛ ብድር መዝገብ ላይ ይመዘገባል እና በቀጣይ ሺፍት ይሰበሰባል።
                    </span>
                  </div>
                )}
              </div>

            </div>

            {/* Progress Bar & Next/Prev Controls */}
            <div className="flex items-center justify-between pt-1">
              <div className="flex items-center gap-2 text-xs font-semibold text-gray-500">
                <span>የተሞላ: {resolvedCount} ከ {totalCount}</span>
                <div className="w-24 h-2 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-emerald-500 transition-all duration-300"
                    style={{ width: `${(resolvedCount / totalCount) * 100}%` }}
                  />
                </div>
              </div>

              <div className="flex gap-2">
                <button
                  type="button"
                  disabled={currentIndex === 0}
                  onClick={() => setCurrentIndex(prev => Math.max(0, prev - 1))}
                  className="px-3.5 py-1.5 border border-gray-300 rounded-lg text-xs font-bold text-gray-700 hover:bg-gray-50 disabled:opacity-30 disabled:cursor-not-allowed flex items-center gap-1 cursor-pointer"
                >
                  <ArrowLeft className="w-3.5 h-3.5" /> ቀዳሚ
                </button>
                <button
                  type="button"
                  disabled={currentIndex === totalCount - 1}
                  onClick={() => setCurrentIndex(prev => Math.min(totalCount - 1, prev + 1))}
                  className="px-3.5 py-1.5 border border-gray-300 rounded-lg text-xs font-bold text-gray-700 hover:bg-gray-50 disabled:opacity-30 disabled:cursor-not-allowed flex items-center gap-1 cursor-pointer"
                >
                  ቀጣይ <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Modal Footer / Final Gate Confirmation (Always Sticky at Bottom) */}
        <div className="modal-footer border-t border-gray-200 bg-gray-50 p-4 sm:px-6 flex flex-col sm:flex-row items-center justify-between gap-3 shrink-0 shadow-inner">
          <div className="flex items-center gap-3 text-xs font-semibold text-gray-600">
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-emerald-500" /> {cashCount} ጥሬ ገንዘብ
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-blue-500" /> {transferCount} ባንክ
            </span>
            <span className="flex items-center gap-1">
              <span className="w-2 h-2 rounded-full bg-purple-500" /> {pendingCount} ብድር
            </span>
          </div>

          <div className="flex items-center gap-2 w-full sm:w-auto">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 border border-gray-300 rounded-xl text-xs font-bold text-gray-700 hover:bg-gray-100 flex-1 sm:flex-none cursor-pointer"
            >
              ተመለስ (Cancel)
            </button>
            <button
              type="button"
              disabled={!isAllResolved}
              onClick={handleFinalSubmit}
              className={`px-5 py-2.5 rounded-xl text-xs font-bold text-white transition-all flex items-center justify-center gap-2 flex-1 sm:flex-none shadow-md ${
                isAllResolved
                  ? 'bg-emerald-700 hover:bg-emerald-800 cursor-pointer animate-in zoom-in-95'
                  : 'bg-gray-300 text-gray-500 cursor-not-allowed'
              }`}
            >
              <Sparkles className="w-4 h-4" />
              <span>አረጋግጥ እና ወደ ማጠቃለያ ቀጥል</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
