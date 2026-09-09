/// Starter vocabulary. Every phrase becomes a kNN anchor for its key on
/// first launch, so the matcher can place a log before the user has
/// confirmed anything. Users can archive, rename, or merge these keys.
///
/// Write phrases the way people type at 11pm, not the way a spec reads.
/// Mixed-language lines are deliberate: MiniLM is English-centric but it
/// still places transliterated words near their English neighbours once
/// there is an anchor to land on.
const Map<String, List<String>> seedLexicon = {
  'sleep': [
    'going to bed', 'slept', 'good night', 'nap', 'lights out', 'bed',
    'couldnt sleep', 'so raha hu', 'in bed', 'crashed',
  ],
  'wake': ['woke up', 'up', 'uth gaya', 'awake', 'morning alarm'],
  'meeting': ['meeting', 'standup', 'sync with', 'call with client', 'review with', 'interview'],
  'call': ['called mom', 'call dad', 'phone call', 'video call', 'rang', 'spoke to'],
  'food': [
    'breakfast', 'lunch', 'dinner', 'ate', 'snack', 'ordered food', 'biryani',
    'dal chawal', 'khana khaya', 'pizza', 'had eggs', 'roti sabzi', 'maggi',
  ],
  'coffee': [
    'coffee', 'chai', 'tea', 'latte', 'filter coffee', 'cutting chai',
    'cold coffee', 'espresso', 'chai break',
  ],
  'gym': [
    'gym', 'workout', 'lifted', 'leg day', 'push day', 'went for a run',
    'jog', 'cycling', 'yoga', 'stretching', 'walked 5k', 'cardio', 'gymmed',
  ],
  'work': [
    'work', 'emails', 'office', 'shipped the fix', 'deploy', 'code review',
    'wfh', 'deep work', 'presentation', 'ticket', 'pr merged',
  ],
  'study': [
    'studied', 'reading', 'homework', 'revision', 'lecture', 'physics',
    'padhai', 'solved problems', 'notes', 'exam prep', 'class', 'assignment',
  ],
  'commute': [
    'commute', 'left for office', 'reached home', 'metro', 'auto', 'bus',
    'cab', 'traffic', 'drove', 'rapido', 'reached college',
  ],
  'social': [
    'met friends', 'hung out', 'dinner with', 'family time',
    'party', 'catch up with', 'date', 'video call', 'visited',
  ],
  'chores': [
    'laundry', 'cleaned room', 'dishes', 'groceries', 'cooked', 'market',
    'paid bills', 'errands', 'sabzi lene gaya', 'organised', 'fixed the tap',
  ],
  'screen': [
    'watched a movie', 'netflix', 'youtube', 'scrolling', 'gaming', 'played valorant',
    'binge', 'reels', 'series', 'twitch',
  ],
  'health': [
    'headache', 'doctor', 'took medicine', 'fever', 'feeling sick', 'meds',
    'dentist', 'period', 'therapy', 'checkup', 'tabiyat kharab',
  ],
  'outdoors': [
    'walk', 'went out', 'park', 'evening walk', 'hike', 'beach', 'trek',
    'sat outside', 'sunset', 'terrace',
  ],
  'creative': [
    'wrote', 'journaling', 'drawing', 'guitar', 'music practice', 'photography',
    'edited video', 'sketch', 'painted', 'piano',
  ],
  'money': [
    'spent', 'bought', 'paid', 'shopping', 'ordered', 'amazon', 'refund',
    'salary credited', 'transfer', 'upi',
  ],
  'misc': [
    'random', 'nothing much', 'thinking', 'idea', 'note to self', 'reminder',
  ],
};
