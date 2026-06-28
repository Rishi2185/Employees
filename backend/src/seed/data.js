'use strict';

/**
 * Seed dataset ported from the patient app's lib/data/mock_data.dart so the
 * hospital backend serves the same roster the patient demo shows. Doctor and
 * hospital ids are preserved verbatim (d1..d12, h1..h5).
 */

// Canonical specialties — ids/names only (icon/color live client-side).
const specialties = [
  { _id: 'general', name: 'General' },
  { _id: 'cardiology', name: 'Cardiology' },
  { _id: 'dermatology', name: 'Dermatology' },
  { _id: 'pediatrics', name: 'Pediatrics' },
  { _id: 'gynecology', name: 'Gynecology' },
  { _id: 'ent', name: 'ENT' },
  { _id: 'neurology', name: 'Neurology' },
  { _id: 'orthopedics', name: 'Orthopedics' },
  { _id: 'dentistry', name: 'Dentistry' },
  { _id: 'ophthalmology', name: 'Eye Care' },
];

const hospitals = [
  {
    _id: 'h1',
    name: 'Aarvy Multispeciality Hospital',
    address: '12 Wellington Road, Bandra West',
    city: 'Mumbai',
    phone: '+91 22 4567 8900',
    imageUrl: 'https://picsum.photos/seed/aarvyhospital/900/600',
    departments: ['Cardiology', 'Neurology', 'Pediatrics', 'Orthopedics', 'General Medicine'],
    about: 'A NABH-accredited multispeciality hospital with 250+ beds.',
    openHours: 'Open 24 hours',
  },
  {
    _id: 'h2',
    name: 'GreenLeaf Heart & Care Centre',
    address: '45 MG Road, Indiranagar',
    city: 'Bengaluru',
    phone: '+91 80 2233 4455',
    imageUrl: 'https://picsum.photos/seed/greenleaf/900/600',
    departments: ['Cardiology', 'ENT', 'Dermatology', 'General Medicine'],
    about: 'A specialised cardiac and wellness centre.',
    openHours: 'Mon - Sat, 8:00 AM - 9:00 PM',
  },
  {
    _id: 'h3',
    name: 'Sunrise Women & Child Clinic',
    address: '88 Park Street',
    city: 'Kolkata',
    phone: '+91 33 6677 8899',
    imageUrl: 'https://picsum.photos/seed/sunrisewc/900/600',
    departments: ['Gynecology', 'Pediatrics', 'Dermatology'],
    about: 'A gentle, family-focused clinic dedicated to women and children.',
    openHours: 'Open 24 hours',
  },
  {
    _id: 'h4',
    name: 'Apex Bone & Joint Institute',
    address: '7 Civil Lines',
    city: 'Delhi',
    phone: '+91 11 4040 5050',
    imageUrl: 'https://picsum.photos/seed/apexbone/900/600',
    departments: ['Orthopedics', 'Neurology', 'General Medicine'],
    about: 'A centre of excellence for orthopedics and sports medicine.',
    openHours: 'Mon - Sun, 7:00 AM - 10:00 PM',
  },
  {
    _id: 'h5',
    name: 'ClearVision Eye & Dental',
    address: '23 Anna Salai',
    city: 'Chennai',
    phone: '+91 44 2828 3939',
    imageUrl: 'https://picsum.photos/seed/clearvision/900/600',
    departments: ['Eye Care', 'Dentistry', 'ENT'],
    about: 'Advanced eye and dental care under one roof.',
    openHours: 'Mon - Sat, 9:00 AM - 8:00 PM',
  },
];

const HOSPITAL_NAMES = Object.fromEntries(hospitals.map((h) => [h._id, h.name]));
const SPECIALTY_NAMES = Object.fromEntries(specialties.map((s) => [s._id, s.name]));

// Doctors are no longer seeded. The roster is managed entirely from the admin
// app via the doctor CRUD endpoints and written to the shared `doctors`
// collection (which the patient backend also reads from).
const doctorSeed = [];

const doctors = doctorSeed.map((d) => ({
  ...d,
  specialtyName: SPECIALTY_NAMES[d.specialtyId],
  hospitalName: HOSPITAL_NAMES[d.hospitalId],
  active: true,
}));

module.exports = { specialties, hospitals, doctors, HOSPITAL_NAMES, SPECIALTY_NAMES };
