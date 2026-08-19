'use client';

import React, { useState } from 'react';
import { Lock, X } from 'lucide-react';

interface PinPadModalProps {
  onConfirm: (pin: string) => void;
  onCancel: () => void;
  title?: string;
  subtitle?: string;
}

export function PinPadModal({ onConfirm, onCancel, title = 'Security Verification', subtitle = 'Enter Cashier 4-digit PIN to confirm shift closure' }: PinPadModalProps) {
  const [pin, setPin] = useState<string>('');
  const [error, setError] = useState<string>('');

  const handleKeyPress = (num: string) => {
    if (pin.length < 4) {
      const nextPin = pin + num;
      setPin(nextPin);
      setError('');
      if (nextPin.length === 4) {
        // Auto submit on 4th digit
        setTimeout(() => {
          onConfirm(nextPin);
        }, 150);
      }
    }
  };

  const handleDelete = () => {
    setPin(prev => prev.slice(0, -1));
    setError('');
  };

  const handleClear = () => {
    setPin('');
    setError('');
  };

  return (
    <div className="pin-overlay">
      <div className="pin-card bg-white p-6 rounded-2xl shadow-2xl border border-gray-200">
        <button className="pin-close icon-button text-gray-400 hover:text-gray-700" onClick={onCancel}>
          <X className="w-5 h-5" />
        </button>

        <div className="lock-icon">
          <Lock className="w-6 h-6" />
        </div>

        <h3>{title}</h3>
        <p className="text-xs text-gray-500 mb-4">{subtitle}</p>

        <div className="pin-dots">
          {[0, 1, 2, 3].map((idx) => (
            <i key={idx} className={idx < pin.length ? 'bg-emerald-600 border-emerald-600' : ''} />
          ))}
        </div>

        {error && <p className="text-red-500 text-xs mb-3 font-semibold">{error}</p>}

        <div className="keypad">
          {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((digit) => (
            <button key={digit} onClick={() => handleKeyPress(digit)} className="text-lg font-bold text-gray-800 hover:bg-gray-100 active:scale-95 transition-transform">
              {digit}
            </button>
          ))}
          <button onClick={handleClear} className="text-xs font-semibold text-gray-500 hover:bg-gray-100">
            Clear
          </button>
          <button onClick={() => handleKeyPress('0')} className="text-lg font-bold text-gray-800 hover:bg-gray-100">
            0
          </button>
          <button onClick={handleDelete} className="text-xs font-semibold text-red-500 hover:bg-red-50">
            ⌫
          </button>
        </div>

        <p className="text-[10px] text-gray-400 mt-4">Default cashier PIN: 1234 or any 4 digits</p>
      </div>
    </div>
  );
}
