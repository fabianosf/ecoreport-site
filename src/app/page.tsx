'use client';

import { useState } from 'react';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import SignupModal from '@/components/common/SignupModal';
import HeroSection from '@/components/sections/HeroSection';
import FeaturesSection from '@/components/sections/FeaturesSection';
import BenefitsSection from '@/components/sections/BenefitsSection';
import PricingSection from '@/components/sections/PricingSection';
import FAQSection from '@/components/sections/FAQSection';
import CTAFinalSection from '@/components/sections/CTAFinalSection';

export default function Home() {
  const [isSignupOpen, setIsSignupOpen] = useState(false);

  return (
    <>
      <Header />
      <main>
        <HeroSection onSignup={() => setIsSignupOpen(true)} />
        <FeaturesSection />
        <BenefitsSection />
        <PricingSection onSignup={() => setIsSignupOpen(true)} />
        <FAQSection />
        <CTAFinalSection onSignup={() => setIsSignupOpen(true)} />
      </main>
      <Footer />
      <SignupModal 
        isOpen={isSignupOpen} 
        onClose={() => setIsSignupOpen(false)} 
      />
    </>
  );
}
