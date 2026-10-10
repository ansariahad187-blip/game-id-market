import React, { useState, useEffect } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, FlatList, ImageBackground, Image,
  StyleSheet, SafeAreaView, ScrollView, StatusBar, Linking, Alert,
  ActivityIndicator, Dimensions,
} from 'react-native';
import * as ImagePicker from 'expo-image-picker';
import { initializeApp, getApps, getApp } from 'firebase/app';
import {
  initializeFirestore, getFirestore, collection, addDoc, onSnapshot,
  query, orderBy, doc, updateDoc, serverTimestamp,
} from 'firebase/firestore';

const FIREBASE = {
  apiKey: 'AIzaSyDNWWMMZcnhalNn0327XcDjc58JDWPLDK8',
  authDomain: 'id-marketing-d1ab9.firebaseapp.com',
  projectId: 'id-marketing-d1ab9',
  storageBucket: 'id-marketing-d1ab9.firebasestorage.app',
  messagingSenderId: '637672446279',
  appId: '1:637672446279:web:d41127c50e75d7c5dd1462',
};

// Photo/video ke liye baad mein Cloudinary ki values yahan daalna
const CLOUD_NAME = 'YOUR_CLOUD_NAME';
const UPLOAD_PRESET = 'YOUR_UNSIGNED_PRESET';
const MEDIA_READY = CLOUD_NAME !== 'YOUR_CLOUD_NAME' && UPLOAD_PRESET !== 'YOUR_UNSIGNED_PRESET';

// Game ki background image ki lines yahan paste karo (khali rahe toh rang dikhega)
const FF_IMG = '';
const BGMI_IMG = '';

const PURPLE = '#7B2FF7';
const DEEP = '#1A0533';
const W = Dimensions.get('window').width;

const app = getApps().length ? getApp() : initializeApp(FIREBASE);
let db;
try {
  db = initializeFirestore(app, { experimentalForceLongPolling: true });
} catch (e) {
  db = getFirestore(app);
}

async function uploadMedia(uri, isVideo) {
  const data = new FormData();
  data.append('file', {
    uri,
    type: isVideo ? 'video/mp4' : 'image/jpeg',
    name: isVideo ? 'v.mp4' : 'p.jpg',
  });
  data.append('upload_preset', UPLOAD_PRESET);
  const res = await fetch(
    `https://api.cloudinary.com/v1_1/${CLOUD_NAME}/${isVideo ? 'video' : 'image'}/upload`,
    { method: 'POST', body: data }
  );
  const json = await res.json();
  if (!json.secure_url) throw new Error((json.error && json.error.message) || 'Upload fail');
  return json.secure_url;
}

const LinearGradient = ({ colors, style, children }) => (
  <View style={[style, { backgroundColor: colors[0] }]}>{children}</View>
);

export default function App() {
  const [screen, setScreen] = useState('login');
  const [tab, setTab] = useState('ff');
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [err, setErr] = useState('');
  const [selId, setSelId] = useState(null);

  useEffect(() => {
    const q = query(collection(db, 'listings'), orderBy('createdAt', 'desc'));
    const unsub = onSnapshot(
      q,
      (snap) => {
        setItems(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
        setLoading(false);
        setErr('');
      },
      (e) => {
        setErr(e.message);
        setLoading(false);
      }
    );
    return unsub;
  }, []);

  if (screen === 'login') return <Login onDone={() => setScreen('home')} />;
  if (screen === 'sell') {
    return (
      <Sell
        onBack={() => setScreen('home')}
        onDone={(g) => {
          setTab(g);
          setScreen('home');
        }}
      />
    );
  }
  if (screen === 'view') {
    return (
      <Detail
        item={items.find((i) => i.id === selId)}
        onBack={() => setScreen('home')}
      />
    );
  }
  return (
    <Home
      tab={tab}
      setTab={setTab}
      items={items}
      loading={loading}
      err={err}
      onSell={() => setScreen('sell')}
      onOpen={(id) => {
        setSelId(id);
        setScreen('view');
      }}
    />
  );
}

function Login({ onDone }) {
  return (
    <LinearGradient colors={['#2A0A5E', '#4B1A99']} style={styles.flex}>
      <StatusBar barStyle="light-content" />
      <SafeAreaView style={[styles.flex, { justifyContent: 'center', padding: 28 }]}>
        <Text style={styles.big}>Game ID Market</Text>
        <Text style={[styles.text, { textAlign: 'center', marginBottom: 30 }]}>
          Free Fire aur BGMI ID kharido ya becho
        </Text>
        <TextInput
          style={styles.input}
          placeholder="Mobile number (+91)"
          placeholderTextColor="#aaa"
          keyboardType="phone-pad"
        />
        <TouchableOpacity style={styles.btn} onPress={onDone}>
          <Text style={styles.btnText}>OTP bhejo</Text>
        </TouchableOpacity>
        <Text style={[styles.text, { textAlign: 'center', marginVertical: 16 }]}>ya</Text>
        <TouchableOpacity style={styles.googleBtn} onPress={onDone}>
          <Text style={styles.googleG}>G</Text>
          <Text style={{ color: '#222', fontSize: 16 }}>Google se Sign in karo</Text>
        </TouchableOpacity>
      </SafeAreaView>
    </LinearGradient>
  );
}

const STATUS = {
  available: { label: 'Available', color: '#2e9e5b' },
  pending: { label: 'Pending', color: '#d9a400' },
  sold: { label: 'Sold', color: '#c0392b' },
};

function Badge({ status }) {
  const s = STATUS[status] || STATUS.available;
  return (
    <View style={[styles.badge, { backgroundColor: s.color }]}>
      <Text style={styles.badgeText}>{s.label}</Text>
    </View>
  );
}

function Home({ tab, setTab, items, loading, err, onSell, onOpen }) {
  const isFF = tab === 'ff';
  const list = items.filter((i) => i.game === tab);
  const bg = isFF ? FF_IMG : BGMI_IMG;
  const bgColor = isFF ? '#8E0E00' : '#0D2B45';
  return (
    <View style={styles.flex}>
      <StatusBar barStyle="light-content" />
      {bg ? (
        <ImageBackground
          source={{ uri: bg }}
          blurRadius={2}
          resizeMode="cover"
          style={[StyleSheet.absoluteFill, { backgroundColor: bgColor }]}
        />
      ) : (
        <View style={[StyleSheet.absoluteFill, { backgroundColor: bgColor }]} />
      )}
      <View style={[StyleSheet.absoluteFill, { backgroundColor: 'rgba(26,5,51,0.5)' }]} />
      <SafeAreaView style={styles.flex}>
        {err ? <Text style={[styles.text, { padding: 16, paddingTop: 36 }]}>Error: {err}</Text> : null}
        <FlatList
          data={list}
          keyExtractor={(i) => i.id}
          contentContainerStyle={{ padding: 12, paddingTop: 30, paddingBottom: 160 }}
          ListEmptyComponent={
            loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.text}>Abhi koi ID nahi hai.</Text>
          }
          renderItem={({ item }) => (
            <TouchableOpacity style={styles.card} onPress={() => onOpen(item.id)}>
              {item.photos && item.photos[0] ? (
                <Image source={{ uri: item.photos[0] }} style={styles.thumb} />
              ) : (
                <View style={[styles.thumb, { backgroundColor: '#3b1a6b' }]} />
              )}
              <View style={{ flex: 1 }}>
                <Text style={styles.cardTitle}>{item.title}</Text>
                <Text style={styles.text}>Level {item.level}</Text>
              </View>
              <View style={{ alignItems: 'flex-end' }}>
                <Text style={styles.price}>₹{item.price}</Text>
                <Badge status={item.status} />
              </View>
            </TouchableOpacity>
          )}
        />
      </SafeAreaView>

      <TouchableOpacity style={styles.fab} onPress={onSell}>
        <Text style={styles.btnText}>+ ID becho</Text>
      </TouchableOpacity>

      <View style={styles.tabBar}>
        <TabBtn label="Free Fire" active={isFF} onPress={() => setTab('ff')} />
        <TabBtn label="BGMI" active={!isFF} onPress={() => setTab('bgmi')} />
      </View>
    </View>
  );
}

function TabBtn({ label, active, onPress }) {
  return (
    <TouchableOpacity style={styles.tabBtn} onPress={onPress}>
      <View style={[styles.pill, active && { backgroundColor: PURPLE }]}>
        <Text style={{ color: '#fff', fontWeight: '600' }}>{label}</Text>
      </View>
    </TouchableOpacity>
  );
}

function Detail({ item, onBack }) {
  if (!item) return null;
  const photos = item.photos || [];
  const setStatus = async (s) => {
    try {
      await updateDoc(doc(db, 'listings', item.id), { status: s });
    } catch (e) {
      Alert.alert('Error', e.message);
    }
  };
  return (
    <View style={[styles.flex, { backgroundColor: DEEP }]}>
      <StatusBar barStyle="light-content" />
      <SafeAreaView style={styles.flex}>
        <ScrollView contentContainerStyle={{ paddingBottom: 40 }}>
          <TouchableOpacity onPress={onBack}>
            <Text style={[styles.text, { padding: 20, paddingTop: 40 }]}>← Wapas</Text>
          </TouchableOpacity>
          {photos.length > 0 && (
            <>
              <ScrollView horizontal pagingEnabled showsHorizontalScrollIndicator={false}>
                {photos.map((u, i) => (
                  <Image key={i} source={{ uri: u }} style={{ width: W, height: 260 }} resizeMode="cover" />
                ))}
              </ScrollView>
              <Text style={[styles.text, { textAlign: 'center', marginTop: 6 }]}>
                {photos.length} photo (swipe karo)
              </Text>
            </>
          )}
          <View style={{ padding: 20 }}>
            <Text style={[styles.big, { textAlign: 'left', fontSize: 24 }]}>{item.title}</Text>
            <View style={{ flexDirection: 'row', alignItems: 'center', marginBottom: 8 }}>
              <Text style={[styles.price, { marginLeft: 0, marginRight: 10 }]}>₹{item.price}</Text>
              <Badge status={item.status} />
            </View>
            <Text style={styles.text}>
              {item.game === 'ff' ? 'Free Fire' : 'BGMI'} | Level {item.level}
            </Text>
            {item.desc ? <Text style={[styles.text, { marginTop: 10 }]}>{item.desc}</Text> : null}

            {item.video ? (
              <TouchableOpacity
                style={[styles.btn, { marginTop: 16 }]}
                onPress={() => Linking.openURL(item.video)}
              >
                <Text style={styles.btnText}>▶ Video dekho</Text>
              </TouchableOpacity>
            ) : null}

            <Text style={[styles.text, { marginTop: 22, marginBottom: 8 }]}>Status badlo:</Text>
            <View style={{ flexDirection: 'row' }}>
              {Object.keys(STATUS).map((k) => (
                <TouchableOpacity
                  key={k}
                  onPress={() => setStatus(k)}
                  style={[
                    styles.statusBtn,
                    { borderColor: STATUS[k].color },
                    item.status === k && { backgroundColor: STATUS[k].color },
                  ]}
                >
                  <Text style={{ color: '#fff', fontWeight: '600' }}>{STATUS[k].label}</Text>
                </TouchableOpacity>
              ))}
            </View>

            <TouchableOpacity
              style={[styles.btn, { marginTop: 24 }]}
              onPress={() => Alert.alert('Jald aa raha hai', 'Chat aur payment agle step mein jodenge.')}
            >
              <Text style={styles.btnText}>Khareedo / Chat</Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

function Sell({ onBack, onDone }) {
  const [game, setGame] = useState('ff');
  const [title, setTitle] = useState('');
  const [level, setLevel] = useState('');
  const [price, setPrice] = useState('');
  const [desc, setDesc] = useState('');
  const [photos, setPhotos] = useState([]);
  const [video, setVideo] = useState('');
  const [busy, setBusy] = useState(false);

  const pickPhotos = async () => {
    const left = 10 - photos.length;
    if (left <= 0) return Alert.alert('Limit', 'Maximum 10 photo.');
    const r = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsMultipleSelection: true,
      selectionLimit: left,
      quality: 0.6,
    });
    if (!r.canceled) setPhotos([...photos, ...r.assets.map((a) => a.uri)].slice(0, 10));
  };

  const pickVideo = async () => {
    const r = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['videos'],
      videoMaxDuration: 60,
    });
    if (!r.canceled) setVideo(r.assets[0].uri);
  };

  const save = async () => {
    const p = parseInt(price, 10);
    if (!title.trim() || isNaN(p)) return Alert.alert('Dhyan do', 'Title aur price sahi daalo');
    setBusy(true);
    try {
      const photoUrls = [];
      let videoUrl = '';
      if (MEDIA_READY) {
        for (const u of photos) photoUrls.push(await uploadMedia(u, false));
        videoUrl = video ? await uploadMedia(video, true) : '';
      } else if (photos.length || video) {
        Alert.alert('Photo upload abhi band hai', 'Cloudinary setup baaki hai, isliye listing photo ke bina daal raha hoon.');
      }
      await addDoc(collection(db, 'listings'), {
        game,
        title: title.trim(),
        level,
        price: p,
        desc,
        photos: photoUrls,
        video: videoUrl,
        status: 'available',
        createdAt: serverTimestamp(),
      });
      onDone(game);
    } catch (e) {
      Alert.alert('Upload fail', e.message);
      setBusy(false);
    }
  };

  const field = (ph, val, set, extra = {}) => (
    <TextInput
      style={styles.input}
      placeholder={ph}
      placeholderTextColor="#aaa"
      value={val}
      onChangeText={set}
      {...extra}
    />
  );

  return (
    <View style={[styles.flex, { backgroundColor: DEEP }]}>
      <StatusBar barStyle="light-content" />
      <SafeAreaView style={styles.flex}>
        <ScrollView contentContainerStyle={{ padding: 20, paddingTop: 40 }}>
          <TouchableOpacity onPress={onBack}>
            <Text style={[styles.text, { marginBottom: 12 }]}>← Wapas</Text>
          </TouchableOpacity>
          <Text style={[styles.big, { textAlign: 'left', fontSize: 24 }]}>ID becho</Text>
          <View style={{ flexDirection: 'row', marginVertical: 14 }}>
            <TabBtn label="Free Fire" active={game === 'ff'} onPress={() => setGame('ff')} />
            <TabBtn label="BGMI" active={game === 'bgmi'} onPress={() => setGame('bgmi')} />
          </View>
          {field('Title (jaise: Elite Pass + 10 skins)', title, setTitle)}
          {field('Level', level, setLevel, { keyboardType: 'numeric' })}
          {field('Price (₹)', price, setPrice, { keyboardType: 'numeric' })}
          {field('Details (skins, rank, etc.)', desc, setDesc, { multiline: true })}

          <Text style={[styles.text, { marginBottom: 8 }]}>Photo ({photos.length}/10)</Text>
          <ScrollView horizontal style={{ marginBottom: 8 }}>
            {photos.map((u, i) => (
              <TouchableOpacity key={i} onPress={() => setPhotos(photos.filter((_, j) => j !== i))}>
                <Image source={{ uri: u }} style={styles.pickThumb} />
              </TouchableOpacity>
            ))}
          </ScrollView>
          {photos.length > 0 ? (
            <Text style={[styles.text, { fontSize: 12, marginBottom: 8 }]}>Photo hatane ke liye usko dabao.</Text>
          ) : null}
          <TouchableOpacity style={styles.outBtn} onPress={pickPhotos}>
            <Text style={styles.btnText}>+ Photo chuno</Text>
          </TouchableOpacity>

          <TouchableOpacity style={[styles.outBtn, { marginTop: 10 }]} onPress={pickVideo}>
            <Text style={styles.btnText}>{video ? 'Video chuna gaya (badalne ke liye dabao)' : '+ Video chuno (max 60 sec)'}</Text>
          </TouchableOpacity>

          <Text style={[styles.text, { fontSize: 12, marginVertical: 14 }]}>
            ID ka password yahan mat likho. Ye payment ke baad chat mein dena hai.
          </Text>
          <TouchableOpacity style={[styles.btn, busy && { opacity: 0.6 }]} onPress={save} disabled={busy}>
            <Text style={styles.btnText}>{busy ? 'Upload ho raha hai...' : 'Listing daalo'}</Text>
          </TouchableOpacity>
        </ScrollView>
      </SafeAreaView>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  big: { color: '#fff', fontSize: 30, fontWeight: '800', textAlign: 'center', marginBottom: 6 },
  text: { color: '#e6dcf5' },
  input: {
    borderWidth: 1, borderColor: '#8d6fd1', borderRadius: 8, padding: 12,
    color: '#fff', marginBottom: 12, fontSize: 16,
  },
  btn: { backgroundColor: PURPLE, padding: 15, borderRadius: 10, alignItems: 'center' },
  outBtn: { borderWidth: 1, borderColor: PURPLE, padding: 13, borderRadius: 10, alignItems: 'center' },
  btnText: { color: '#fff', fontSize: 16, fontWeight: '700' },
  googleBtn: {
    backgroundColor: '#fff', padding: 13, borderRadius: 10,
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
  },
  googleG: { color: '#DB4437', fontWeight: '900', fontSize: 20, marginRight: 10 },
  card: {
    backgroundColor: 'rgba(26,5,51,0.78)', borderRadius: 12, padding: 10,
    marginBottom: 10, flexDirection: 'row', alignItems: 'center',
  },
  thumb: { width: 56, height: 56, borderRadius: 8, marginRight: 10 },
  pickThumb: { width: 70, height: 70, borderRadius: 8, marginRight: 8 },
  cardTitle: { color: '#fff', fontSize: 16, fontWeight: '700', marginBottom: 4 },
  price: { color: '#fff', fontSize: 18, fontWeight: '800', marginLeft: 8 },
  badge: { paddingVertical: 2, paddingHorizontal: 8, borderRadius: 10, marginTop: 4 },
  badgeText: { color: '#fff', fontSize: 11, fontWeight: '700' },
  statusBtn: { borderWidth: 2, borderRadius: 18, paddingVertical: 8, paddingHorizontal: 14, marginRight: 8 },
  fab: {
    position: 'absolute', right: 16, bottom: 86, backgroundColor: PURPLE,
    paddingVertical: 14, paddingHorizontal: 20, borderRadius: 28, elevation: 6,
  },
  tabBar: {
    position: 'absolute', left: 0, right: 0, bottom: 0, height: 70,
    backgroundColor: DEEP, flexDirection: 'row', paddingBottom: 6,
  },
  tabBtn: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  pill: { paddingVertical: 10, paddingHorizontal: 26, borderRadius: 20 },
});
