import { pool } from '../db/pool';
import { ContactService } from '../services/contact.service';

async function runContactsTests() {
  console.log('=== Starting Backend Contacts Tab Test Suite ===');
  const client = await pool.connect();

  try {
    // 1. Create Test User
    const testPhone = `+23480${Math.floor(10000000 + Math.random() * 90000000)}`;
    const userRes = await client.query(`
      INSERT INTO users (phone_number, full_name, business_name, avatar_id)
      VALUES ($1, 'Test Contacts User', 'Contacts Inc', 1)
      RETURNING id, phone_number
    `, [testPhone]);
    const user = userRes.rows[0];

    const testContactPhone = `+23481${Math.floor(10000000 + Math.random() * 90000000)}`;
    const partnerRes = await client.query(`
      INSERT INTO users (phone_number, full_name, business_name, avatar_id)
      VALUES ($1, 'Partner Biz', 'Partner LLC', 2)
      RETURNING id, phone_number
    `, [testContactPhone]);
    const partner = partnerRes.rows[0];

    // Insert user_contact record
    const contactRes = await client.query(`
      INSERT INTO user_contacts (owner_id, contact_user_id, external_name, external_phone)
      VALUES ($1, $2, 'Partner Biz', $3)
      RETURNING id
    `, [user.id, partner.id, testContactPhone]);
    const contactRecord = contactRes.rows[0];

    console.log('✔ Test data initialized.');

    // 2. Test Get User Contacts
    const contacts = await ContactService.getUserContacts(user.id);
    if (contacts.length !== 1 || contacts[0]?.id !== contactRecord.id) {
      throw new Error(`Expected 1 contact, got ${contacts.length}`);
    }
    console.log('✔ 1. ContactService.getUserContacts returns active Square contacts');

    // 3. Test Update Contact (Star & Labels)
    await ContactService.updateContact(user.id, contactRecord.id, {
      isStarred: true,
      notes: 'VIP Partner for electronics supply',
      labels: ['VIP', 'Electronics'],
    });

    const updated = await ContactService.getUserContacts(user.id);
    if (!updated[0]?.isStarred || !updated[0]?.labels.includes('VIP')) {
      throw new Error('Contact update failed for star or labels');
    }
    console.log('✔ 2. ContactService.updateContact updates star and assigns labels');

    // 4. Test Labels API
    const labels = await ContactService.getLabels(user.id);
    if (labels.length < 2 || !labels.some(l => l.name === 'VIP')) {
      throw new Error(`Expected at least 2 labels, got ${labels.length}`);
    }
    console.log('✔ 3. ContactService.getLabels lists labels with contact count');

    // 5. Test Bulk Archive
    await ContactService.bulkUpdate(user.id, [contactRecord.id], 'archive');
    const activeAfterArchive = await ContactService.getUserContacts(user.id, false);
    const allIncludingArchived = await ContactService.getUserContacts(user.id, true);

    if (activeAfterArchive.length !== 0 || allIncludingArchived.length !== 1) {
      throw new Error('Archive filtering failed');
    }
    console.log('✔ 4. ContactService.bulkUpdate handles archive and filter isolation');

    // 6. Test Bulk Restore
    await ContactService.bulkUpdate(user.id, [contactRecord.id], 'restore');
    const restored = await ContactService.getUserContacts(user.id, false);
    if (restored.length !== 1) {
      throw new Error('Restore failed');
    }
    console.log('✔ 5. ContactService.bulkUpdate restores archived contacts');

    // 7. Test Label Deletion Without Contact Deletion
    const vipLabel = labels.find(l => l.name === 'VIP')!;
    await ContactService.deleteLabel(user.id, vipLabel.id);
    const contactsAfterLabelDelete = await ContactService.getUserContacts(user.id);
    if (contactsAfterLabelDelete.length !== 1) {
      throw new Error('Contact was deleted when label was deleted');
    }
    console.log('✔ 6. ContactService.deleteLabel deletes label safely without affecting contacts');

    // 8. Test Device Sync Acknowledgment
    await ContactService.acknowledgeDeviceSync(user.id, [partner.id], 'SYNCED');
    console.log('✔ 7. ContactService.acknowledgeDeviceSync acknowledges device storage');

    // Clean up
    await client.query(`DELETE FROM users WHERE id IN ($1, $2)`, [user.id, partner.id]);
    console.log('✔ Cleanup complete.');

    console.log('🎉 ALL BACKEND CONTACTS TAB TESTS PASSED!');
  } catch (error) {
    console.error('❌ Contacts tests failed:', error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runContactsTests();
