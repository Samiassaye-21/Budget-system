'use client';

import React from 'react';
import { X, FileSpreadsheet } from 'lucide-react';
import { ShiftSession, Order, CustomerDebt, ShiftReconciliation, KitchenTicket, ManualShiftReconciliation } from '../types/pos';
import { dataService } from '../lib/dataService';
import { ShiftReconciliationPage } from './ShiftReconciliationPage';

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
  const products = dataService.getProductsSync();
  const config = dataService.getConfig();

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-3 md:p-6 overflow-y-auto animate-fadeIn">
      <div className="bg-[#f7f5f0] text-[#0B1D2C] w-full max-w-5xl rounded-3xl border border-[#0B1D2C]/20 shadow-2xl flex flex-col max-h-[94vh] overflow-hidden">
        
        {/* MODAL HEADER */}
        <div className="p-4 md:px-6 bg-white border-b border-[#0B1D2C]/15 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="p-2.5 bg-[#0B1D2C] text-amber-400 rounded-2xl shadow-md">
              <FileSpreadsheet className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="font-extrabold text-lg md:text-xl text-[#0B1D2C] tracking-tight">
                  End of Shift Reconciliation
                </h2>
                <span className="px-2.5 py-0.5 text-[10px] font-black uppercase rounded-full bg-amber-500 text-black">
                  {shiftSession.shiftType === 'day' ? '☀️ Day Shift' : '🌙 Night Shift'}
                </span>
              </div>
              <p className="text-xs text-[#0B1D2C]/60">
                Cashier: <strong>{shiftSession.cashierName}</strong> • Maraki Stock &amp; Cash Handover System
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            className="p-2 rounded-xl text-gray-500 hover:text-black hover:bg-gray-100 transition"
            title="Close"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* MODAL SCROLLABLE BODY */}
        <div className="flex-1 overflow-y-auto p-4 md:p-8">
          <ShiftReconciliationPage
            products={products}
            debts={initialDebts}
            config={config}
            activeShift={shiftSession.shiftType}
            selectedDate={new Date().toISOString().slice(0, 10)}
            onShiftChange={() => {}}
            onDateChange={() => {}}
            onReconciliationSaved={(recon: ManualShiftReconciliation) => {
              onCompleteReconciliation(recon);
            }}
          />
        </div>

      </div>
    </div>
  );
}
