'use client';

import React, { useState, useEffect } from 'react';
import { ArrowRight, Check, Sun, Moon, Lock, AlertCircle, ShieldCheck } from 'lucide-react';
import { ShiftType } from '../types/pos';
import { dataService } from '../lib/dataService';
import { PinPadModal } from './PinPadModal';

interface CupSetupProps {
  shift: ShiftType;
  onStart: (cups: number) => void;
  onBack: () => void;
}

export function CupSetup({ shift, onStart, onBack }: CupSetupProps) {
  const [expectedCups, setExpectedCups] = useState<number>(120);
  const [openingCups, setOpeningCups] = useState<string>('');
  const [isAdminApproved, setIsAdminApproved] = useState<boolean>(false);
  const [showAdminPinModal, setShowAdminPinModal] = useState<boolean>(false);

  useEffect(() => {
    // Fetch previous shift's recorded leftover count
    const lastLeftover = dataService.getLastLeftoverCups();
    setExpectedCups(typeof lastLeftover === 'number' ? lastLeftover : 120);
  }, []);

  const numOpeningCups = openingCups === '' ? null : Number(openingCups);
  const isEntered = numOpeningCups !== null && !isNaN(numOpeningCups);
  const diff = isEntered ? numOpeningCups - expectedCups : null;
  const isMatched = isEntered && diff === 0;
  const canProceed = (isMatched || isAdminApproved) && isEntered && numOpeningCups >= 0;

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const val = e.target.value.replace(/^0+(?=\d)/, '');
    setOpeningCups(val);
    setIsAdminApproved(false);
  };

  const handleAdminPinSuccess = (pin: string) => {
    setIsAdminApproved(true);
    setShowAdminPinModal(false);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (canProceed && numOpeningCups !== null) {
      onStart(numOpeningCups);
    }
  };

  return (
    <main className="shift-gate">
      <section className="setup-card max-w-md w-full p-6 bg-white rounded-2xl shadow-xl border border-gray-200">
        <button className="back-link mb-2 text-xs font-semibold text-gray-500 hover:text-gray-900" onClick={onBack}>
          ← የስራ ቦታ ይለውጡ
        </button>

        <div className="setup-icon w-12 h-12 rounded-2xl bg-amber-50 flex items-center justify-center mb-3">
          {shift === 'day' ? <Sun className="w-6 h-6 text-amber-600" /> : <Moon className="w-6 h-6 text-purple-600" />}
        </div>

        <p className="eyebrow text-xs font-bold text-gray-400">
          {shift === 'day' ? '☀ የቀን ሺፍት' : '☾ የማታ ሺፍት'} / ሬጅስተር መክፈቻ
        </p>
        <h1 className="text-xl sm:text-2xl font-black text-gray-900 mt-0.5">ተረካቢ የብርጭቆ ብዛት</h1>
        <p className="gate-copy text-xs text-gray-600 mt-1 mb-5">
          ከቀደመው ሺፍት የተረፈውን የብርጭቆ ብዛት በአካል ቆጥረው ያስገቡ። ቆጠራው ከቀደመው ሺፍት ርክክብ ጋር ይረጋገጣል።
        </p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <label className="cup-field block">
            <span className="flex justify-between items-center text-xs font-bold text-gray-800 mb-1.5">
              <span>የተረከቡት የብርጭቆ ብዛት (Physical Received) <span className="text-red-500">*ግዴታ</span></span>
              {isAdminApproved && (
                <span className="text-[10px] text-emerald-700 bg-emerald-50 border border-emerald-200 px-2 py-0.5 rounded flex items-center gap-1 font-bold">
                  <ShieldCheck className="w-3 h-3" /> በአድሚን ጸድቋል
                </span>
              )}
            </span>
            <input
              type="number"
              min="0"
              placeholder="የቆጠሩትን ብርጭቆ ያስገቡ..."
              value={openingCups}
              onFocus={(e) => e.target.select()}
              onChange={handleInputChange}
              className="w-full border-2 border-primary rounded-xl p-3 text-lg font-black outline-primary bg-white shadow-inner"
            />
          </label>

          {/* Validation Feedback */}
          {!isEntered ? (
            <div className="p-3.5 bg-amber-50 border border-amber-200 rounded-xl flex items-center gap-2.5 text-xs text-amber-900 font-medium">
              <AlertCircle className="w-4 h-4 text-amber-600 shrink-0" />
              <span>እባክዎ በአካል የቆጠሩትን ተረካቢ የብርጭቆ ብዛት ያስገቡ።</span>
            </div>
          ) : isMatched ? (
            <div className="p-3.5 bg-emerald-50 border border-emerald-300 rounded-xl space-y-1">
              <div className="flex items-center gap-1.5 text-xs font-black text-emerald-900">
                <Check className="w-4 h-4 text-emerald-600 shrink-0" />
                <span>✓ ልክ ተጣጥሟል! (0 ልዩነት)</span>
              </div>
              <p className="text-[11px] text-emerald-700 font-semibold">
                ከቀደመው ሺፍት የተረፈው <strong>{expectedCups}</strong> ብርጭቆ በትክክል ተረክበዋል።
              </p>
            </div>
          ) : isAdminApproved ? (
            <div className="p-3.5 bg-emerald-50 border border-emerald-300 rounded-xl text-xs text-emerald-900 font-bold flex items-center gap-2">
              <Check className="w-4 h-4 text-emerald-600" />
              <span>የብርጭቆ ልዩነት በአድሚን PIN ጸድቋል። ሺፍት መጀመር ይችላሉ።</span>
            </div>
          ) : (
            <div className="space-y-3">
              <div className="p-3.5 bg-red-50 border-2 border-red-300 rounded-xl space-y-1.5">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-black text-red-900 flex items-center gap-1.5">
                    <AlertCircle className="w-4 h-4 text-red-600 shrink-0" /> የብርጭቆ ልዩነት ተገኝቷል!
                  </span>
                  <span className="px-2.5 py-0.5 bg-red-100 text-red-800 text-[11px] font-black rounded-full">
                    {diff! > 0 ? `+${diff} ብርጭቆ ትርፍ` : `${diff} ብርጭቆ ጉድለት`}
                  </span>
                </div>
                <div className="text-xs text-gray-700 space-y-0.5 pt-1">
                  <div>• ከቀደመው ሺፍት የተረፈው መዝገብ: <strong className="text-gray-900">{expectedCups} ብርጭቆ</strong></div>
                  <div>• እርስዎ ያስገቡት ቆጠራ: <strong className="text-red-700">{numOpeningCups} ብርጭቆ</strong></div>
                </div>
              </div>

              <button
                type="button"
                onClick={() => setShowAdminPinModal(true)}
                className="w-full py-2 px-3 border border-amber-400 bg-amber-50 hover:bg-amber-100 text-amber-950 font-bold text-xs rounded-xl flex items-center justify-center gap-1.5 transition-colors cursor-pointer"
              >
                <Lock className="w-3.5 h-3.5 text-amber-700" />
                <span>ልዩነቱን በአድሚን PIN አጽድቅ (Approve with Admin PIN)</span>
              </button>
            </div>
          )}

          {/* Submit Button */}
          <button
            type="submit"
            className={`w-full py-3.5 rounded-xl font-black text-xs sm:text-sm text-white transition-all flex items-center justify-center gap-2 shadow-md ${
              canProceed
                ? 'bg-primary hover:bg-primary/90 cursor-pointer'
                : 'bg-gray-300 text-gray-500 cursor-not-allowed shadow-none'
            }`}
            disabled={!canProceed}
          >
            {canProceed
              ? `${shift === 'day' ? 'የቀን' : 'የማታ'} ሺፍት ጀምር`
              : (openingCups === '' ? 'ቆጠራውን ያስገቡ' : 'ልዩነቱን ያስተካክሉ (Fix Discrepancy)')}
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        <div className="setup-note mt-4 p-3 bg-gray-50 rounded-xl text-gray-600 text-xs flex items-center gap-2">
          <Check className="w-4 h-4 text-emerald-600 shrink-0" />
          <span>በሺፍት ማጠቃለያ (Reconciliation) ጊዜ ተጨማሪ ብርጭቆዎችን ማስተካከል ይችላሉ።</span>
        </div>
      </section>

      {/* Admin PIN Approval Modal */}
      {showAdminPinModal && (
        <PinPadModal
          onCancel={() => setShowAdminPinModal(false)}
          onConfirm={handleAdminPinSuccess}
          title="የአድሚን ፈቃድ ማረጋገጫ (Admin Approval)"
          subtitle="የብርጭቆ ልዩነትን አጽድቆ ሺፍት ለመጀመር የአድሚን 4-ዲጂት PIN ያስገቡ"
        />
      )}
    </main>
  );
}
