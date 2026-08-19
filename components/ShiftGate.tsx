'use client';

import React from 'react';
import { ChevronRight, Sun, Moon, UtensilsCrossed, Settings } from 'lucide-react';
import { ShiftType } from '../types/pos';
import { isSupabaseConfigured } from '../lib/supabase';

interface ShiftGateProps {
  onSelectShift: (shift: ShiftType) => void;
  onSelectKitchen: () => void;
  onSelectAdmin: () => void;
}

export function ShiftGate({ onSelectShift, onSelectKitchen, onSelectAdmin }: ShiftGateProps) {
  return (
    <main className="shift-gate">
      <div className="gate-orb orb-one" />
      <div className="gate-orb orb-two" />
      <section className="gate-card">
        <div className="flex justify-between items-start mb-6">
          <div className="brand gate-brand flex items-center gap-3">
            <img src="/logo.jpg" alt="Maraki Logo" className="w-14 h-14 rounded-full object-cover border-2 border-amber-400 shadow-md" />
            <div>
              <strong className="text-2xl">ማራኪ <span>POS</span></strong>
              <small className="tracking-widest">አዲስ አበባ • ቦሌ ቅርንጫፍ</small>
            </div>
          </div>
          <button
            onClick={onSelectAdmin}
            className="p-2 border border-gray-200 rounded-xl hover:bg-gray-50 flex items-center gap-1.5 text-xs text-gray-500 font-semibold"
            title="Supabase & Admin Configuration"
          >
            <Settings className="w-4 h-4 text-gray-600" /> Admin / Supabase
          </button>
        </div>

        <p className="eyebrow">እንኳን ደህና መጡ</p>
        <h1 className="font-extrabold text-gray-900">የስራ ቦታዎን ይምረጡ</h1>
        <p className="gate-copy">አዲስ ሺፍት ለመጀመር ወይም የኩሽና ማዘዣዎችን ለመላክ ከታች ካሉት ይምረጡ።</p>
        
        <div className="workspace-choices mt-6">
          <button onClick={() => onSelectShift('day')}>
            <span className="choice-icon sun"><Sun className="w-5 h-5 text-amber-600" /></span>
            <span>
              <strong className="text-base text-gray-900">ቀን ሺፍት (Day Shift)</strong>
              <small className="text-xs text-gray-500">የጠዋት እና የከሰዓት የካሽ ሬጅስተር አገልግሎት ይክፈቱ</small>
            </span>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>

          <button onClick={() => onSelectShift('night')}>
            <span className="choice-icon moon"><Moon className="w-5 h-5 text-indigo-500" /></span>
            <span>
              <strong className="text-base text-gray-900">ማታ ሺፍት (Night Shift)</strong>
              <small className="text-xs text-gray-500">የማታ የካሽ ሬጅስተር እና የቡድን አገልግሎት ይቀጥሉ</small>
            </span>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>

          <button onClick={onSelectKitchen}>
            <span className="choice-icon kitchen"><UtensilsCrossed className="w-5 h-5 text-orange-600" /></span>
            <span>
              <strong className="text-base text-gray-900">ኪችን / ኩሽና ማዘዣ (Kitchen Display)</strong>
              <small className="text-xs text-gray-500">የምግብ ማዘዣዎችን በቀጥታ ወደ ኩሽና ያስተላልፉ</small>
            </span>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>
        </div>

        <div className="gate-footer border-t border-gray-100 pt-4 mt-8 flex justify-between text-xs text-gray-500">
          <div className="flex items-center gap-1.5">
            <span className="online-dot" />
            {isSupabaseConfigured ? 'ከ Supabase BaaS ጋር ተያይዟል' : 'ሎካል ሲስተም • Supabase ዝግጁ'}
          </div>
          <span>ማራኪ POS v2.6</span>
        </div>
      </section>
    </main>
  );
}
