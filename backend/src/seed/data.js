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

// Compact doctor seed; denormalized specialtyName/hospitalName filled below.
const doctorSeed = [
  { _id: 'd1', name: 'Dr. Ananya Sharma', specialtyId: 'cardiology', qualifications: 'MBBS, MD, DM (Cardiology)', experienceYears: 14, rating: 4.9, reviewCount: 328, consultationFee: 800, about: 'Senior interventional cardiologist focused on preventive care.', photoUrl: 'https://randomuser.me/api/portraits/women/68.jpg', hospitalId: 'h2', languages: ['English', 'Hindi', 'Kannada'], patientsServed: 12000, availableToday: true, availableDays: ['Mon', 'Tue', 'Wed', 'Fri', 'Sat'], consultStart: '09:00', consultEnd: '17:00' },
  { _id: 'd2', name: 'Dr. Rohan Mehta', specialtyId: 'dermatology', qualifications: 'MBBS, MD (Dermatology)', experienceYears: 9, rating: 4.7, reviewCount: 211, consultationFee: 600, about: 'Cosmetic and clinical dermatologist with a gentle approach.', photoUrl: 'https://randomuser.me/api/portraits/men/32.jpg', hospitalId: 'h2', languages: ['English', 'Hindi'], patientsServed: 8500, availableToday: true, availableDays: ['Mon', 'Wed', 'Thu', 'Fri'], consultStart: '10:00', consultEnd: '18:00' },
  { _id: 'd3', name: 'Dr. Priya Nair', specialtyId: 'gynecology', qualifications: 'MBBS, MS (Obstetrics & Gynecology)', experienceYears: 16, rating: 4.9, reviewCount: 402, consultationFee: 750, about: 'Compassionate gynecologist and obstetrician.', photoUrl: 'https://randomuser.me/api/portraits/women/65.jpg', hospitalId: 'h3', languages: ['English', 'Hindi', 'Malayalam', 'Bengali'], patientsServed: 15000, availableToday: false, availableDays: ['Tue', 'Wed', 'Thu', 'Sat'], consultStart: '09:30', consultEnd: '16:00' },
  { _id: 'd4', name: 'Dr. Arjun Verma', specialtyId: 'pediatrics', qualifications: 'MBBS, MD (Pediatrics)', experienceYears: 11, rating: 4.8, reviewCount: 276, consultationFee: 550, about: 'Friendly pediatrician specialising in newborn care.', photoUrl: 'https://randomuser.me/api/portraits/men/45.jpg', hospitalId: 'h3', languages: ['English', 'Hindi', 'Bengali'], patientsServed: 9800, availableToday: true, availableDays: ['Mon', 'Tue', 'Thu', 'Fri', 'Sat'], consultStart: '11:00', consultEnd: '19:00' },
  { _id: 'd5', name: 'Dr. Kavya Reddy', specialtyId: 'ent', qualifications: 'MBBS, MS (ENT)', experienceYears: 8, rating: 4.6, reviewCount: 154, consultationFee: 500, about: 'ENT surgeon experienced in minimally invasive techniques.', photoUrl: 'https://randomuser.me/api/portraits/women/44.jpg', hospitalId: 'h5', languages: ['English', 'Telugu', 'Tamil'], patientsServed: 6400, availableToday: true, availableDays: ['Mon', 'Wed', 'Fri', 'Sat'], consultStart: '09:00', consultEnd: '15:00' },
  { _id: 'd6', name: 'Dr. Vikram Singh', specialtyId: 'orthopedics', qualifications: 'MBBS, MS (Orthopedics)', experienceYears: 18, rating: 4.8, reviewCount: 389, consultationFee: 900, about: 'Leading orthopedic and joint-replacement surgeon.', photoUrl: 'https://randomuser.me/api/portraits/men/52.jpg', hospitalId: 'h4', languages: ['English', 'Hindi', 'Punjabi'], patientsServed: 13500, availableToday: false, availableDays: ['Tue', 'Thu', 'Fri', 'Sat'], consultStart: '08:00', consultEnd: '14:00' },
  { _id: 'd7', name: 'Dr. Meera Iyer', specialtyId: 'neurology', qualifications: 'MBBS, DM (Neurology)', experienceYears: 13, rating: 4.7, reviewCount: 198, consultationFee: 950, about: 'Neurologist specialising in migraine, epilepsy and movement disorders.', photoUrl: 'https://randomuser.me/api/portraits/women/12.jpg', hospitalId: 'h4', languages: ['English', 'Hindi', 'Tamil'], patientsServed: 7200, availableToday: true, availableDays: ['Mon', 'Tue', 'Wed', 'Thu'], consultStart: '10:00', consultEnd: '17:00' },
  { _id: 'd8', name: 'Dr. Sameer Khan', specialtyId: 'general', qualifications: 'MBBS, MD (General Medicine)', experienceYears: 10, rating: 4.6, reviewCount: 245, consultationFee: 400, about: 'General physician handling everyday health concerns and check-ups.', photoUrl: 'https://randomuser.me/api/portraits/men/76.jpg', hospitalId: 'h1', languages: ['English', 'Hindi', 'Urdu'], patientsServed: 11000, availableToday: true, availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'], consultStart: '09:00', consultEnd: '20:00' },
  { _id: 'd9', name: 'Dr. Neha Gupta', specialtyId: 'dentistry', qualifications: 'BDS, MDS (Prosthodontics)', experienceYears: 7, rating: 4.8, reviewCount: 167, consultationFee: 450, about: 'Cosmetic dentist focused on pain-free dentistry and implants.', photoUrl: 'https://randomuser.me/api/portraits/women/90.jpg', hospitalId: 'h5', languages: ['English', 'Hindi'], patientsServed: 5300, availableToday: true, availableDays: ['Mon', 'Wed', 'Thu', 'Fri', 'Sat'], consultStart: '10:00', consultEnd: '19:00' },
  { _id: 'd10', name: 'Dr. Rahul Desai', specialtyId: 'ophthalmology', qualifications: 'MBBS, MS (Ophthalmology)', experienceYears: 12, rating: 4.7, reviewCount: 188, consultationFee: 550, about: 'Eye surgeon experienced in LASIK and cataract procedures.', photoUrl: 'https://randomuser.me/api/portraits/men/15.jpg', hospitalId: 'h5', languages: ['English', 'Hindi', 'Tamil'], patientsServed: 8800, availableToday: false, availableDays: ['Tue', 'Wed', 'Fri', 'Sat'], consultStart: '09:00', consultEnd: '16:00' },
  { _id: 'd11', name: 'Dr. Ishaan Joshi', specialtyId: 'cardiology', qualifications: 'MBBS, MD, DNB (Cardiology)', experienceYears: 20, rating: 4.9, reviewCount: 511, consultationFee: 1000, about: 'Veteran cardiologist with two decades of clinical excellence.', photoUrl: 'https://randomuser.me/api/portraits/men/3.jpg', hospitalId: 'h1', languages: ['English', 'Hindi', 'Marathi'], patientsServed: 21000, availableToday: true, availableDays: ['Mon', 'Tue', 'Thu', 'Fri'], consultStart: '08:00', consultEnd: '13:00' },
  { _id: 'd12', name: 'Dr. Sara Thomas', specialtyId: 'pediatrics', qualifications: 'MBBS, DCH, MD (Pediatrics)', experienceYears: 6, rating: 4.7, reviewCount: 132, consultationFee: 500, about: 'Energetic pediatrician supporting first-time parents.', photoUrl: 'https://randomuser.me/api/portraits/women/29.jpg', hospitalId: 'h1', languages: ['English', 'Hindi', 'Malayalam'], patientsServed: 4200, availableToday: true, availableDays: ['Mon', 'Wed', 'Fri', 'Sat'], consultStart: '11:00', consultEnd: '18:00' },
];

const doctors = doctorSeed.map((d) => ({
  ...d,
  specialtyName: SPECIALTY_NAMES[d.specialtyId],
  hospitalName: HOSPITAL_NAMES[d.hospitalId],
  active: true,
}));

module.exports = { specialties, hospitals, doctors, HOSPITAL_NAMES, SPECIALTY_NAMES };
