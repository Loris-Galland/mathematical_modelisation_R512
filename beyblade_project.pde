// --- PARAMÈTRES GÉNÉRAUX ---
double dt = 0.015;
double t = 0;

// --- PARAMÈTRES ARÈNE ---
double courbure = 0.0010;     
double R_arene = 380;

// --- ÉTAT TOUPIE ---
double x = 0, y = 0, z = 0; 
double vx = 0, vy = 0;

// Angles
double theta = 0.2;           // Inclinaison
double phi = 0;               // Rotation (Spin)

// Vitesses
double omega_phi = 0;         
double omega_theta = 0;       

// --- PHYSIQUE ---
double m = 1.0;
double g = 9.81;
double L = 50;                
double C = 10;                
double A = 5;                 

// --- DIMENSIONS VISUELLES (Pour les collisions) ---
float rayon_disque = 20.0;    // Rayon du cylindre bleu

// --- RÉGLAGES FROTTEMENTS ---
double frot_air = 0.035;      // Frottement air
double frot_sol = 0.008;      // Frottement déplacement
double frot_pointe = 0.8;     // Frottement mécanique constant
double facteur_drive = 0.25;  // Force de mouvement orbital

// Seuil de stabilité (plus bas car elle tourne moins vite)
double seuil_critique = 15.0; 

boolean lancee = false; 

void setup() {
  size(800, 800, P3D);
  noStroke();
}

void draw() {
  background(30);
  
  ambientLight(100, 100, 100);
  directionalLight(255, 255, 255, 0, 1, -1);
  
  // Caméra
  float camX = (float)x * 0.4;
  float camY = (float)y * 0.4 - 600;
  camera(camX, camY, 700, (float)x*0.1, (float)y*0.1, 0, 0, 0, -1);

  if (lancee) {
    // ------------------------------------------------
    // 1. DÉPLACEMENT
    // ------------------------------------------------
    double r = Math.sqrt(x*x + y*y);
    double angle_pos = Math.atan2(y, x);

    // Gravité Pente
    double angle_pente = Math.atan(2 * courbure * r);
    double F_rappel = -m * g * Math.sin(angle_pente);
    
    // Centrifuge
    double F_centri = omega_phi * 0.01;
    
    // Drive (Mouvement latéral)
    double force_tangentielle = 0;
    if (theta < PI/2 - 0.1) {
       force_tangentielle = omega_phi * Math.sin(theta) * facteur_drive;
    }

    double F_radial = F_rappel + F_centri;
    double ax = F_radial * Math.cos(angle_pos);
    double ay = F_radial * Math.sin(angle_pos);
    
    // Ajout force tangentielle (Orbite)
    ax += force_tangentielle * Math.cos(angle_pos + PI/2);
    ay += force_tangentielle * Math.sin(angle_pos + PI/2);
    
    vx += ax * dt; vy += ay * dt;
    vx -= vx * frot_sol; vy -= vy * frot_sol;
    
    // Mur
    if (r > R_arene) {
       double nx = Math.cos(angle_pos); double ny = Math.sin(angle_pos);
       x = nx * (R_arene - 2); y = ny * (R_arene - 2);
       double v_dot = vx*nx + vy*ny;
       if(v_dot > 0) {
         vx -= 1.2 * v_dot * nx; vy -= 1.2 * v_dot * ny;
         omega_phi *= 0.8; 
       }
    }
    
    x += vx; y += vy;
    z = courbure * x * x + courbure * y * y; 

    // ------------------------------------------------
    // 2. ROTATION & CHUTE
    // ------------------------------------------------

    double acc_theta = (m * g * L * Math.sin(theta) 
                      - A * omega_phi * omega_phi * Math.cos(theta) * Math.sin(theta)) / C;
    
    // Force de chute quand la vitesse est basse
    if (omega_phi < seuil_critique) {
       double faiblesse = (seuil_critique - omega_phi) / seuil_critique; 
       acc_theta += 2.5 * faiblesse; 
    }

    acc_theta -= 0.3 * omega_theta; 
    
    omega_theta += acc_theta * dt;
    theta += omega_theta * dt;
    
    if(theta < 0.05) theta = 0.05;

    // Ralentissement
    omega_phi -= frot_air * omega_phi * dt;
    if (omega_phi > 0) omega_phi -= frot_pointe * dt;
    
    // Frottement au sol si couchée
    if(theta > 0.5) {
       omega_phi -= 2.0 * dt; 
       vx *= 0.96; vy *= 0.96;
    }
    
    if (omega_phi < 0) omega_phi = 0;
    
    // Arrêt (Couchée)
    if(theta > PI/2 - 0.1) {
      theta = PI/2 - 0.1;
      omega_phi = 0;
      vx = 0; vy = 0;
    }
    
    phi += omega_phi * dt;
  }

  // ------------------------------------------------
  // 3. DESSIN & CORRECTION SOL
  // ------------------------------------------------
  drawArena();
  
  if (lancee || (!lancee && frameCount % 30 < 15)) { 
    pushMatrix();
    translate((float)x, (float)y, (float)z);
    
    // --- CORRECTION ANTI-TRAVERSÉE ---
    // Quand theta approche de 90° (PI/2), le bord du disque (rayon 20) touche le sol.
    // Il faut soulever la toupie pour que le bord repose SUR le sol z, et pas dessous.
    // Formule : sin(theta) * rayon
    float lift = (float)Math.sin(theta) * rayon_disque;
    
    // On applique le lift seulement si elle penche significativement
    if (lift < 4.0) lift = 0; // La pointe touche
    else lift -= 4.0;         // Transition douce vers le bord
    
    translate(0, 0, lift); 
    // ----------------------------------
    
    rotateZ((float)phi);   
    rotateY((float)theta); 
    
    // --- APPARENCE ORIGINALE ---
    fill(100);
    pushMatrix();
    fill(150, 170, 255);
    translate(0,0,(float) L);
    rotateX(PI);
    drawCone(4,(float) L, 10); 
    popMatrix();

    translate(0,0,(float) L);
    fill(150, 170, 255);
    cylinder(rayon_disque, 4); // Utilisation de rayon_disque (20)

    fill(255,255,0);
    translate(15, 0, 2);
    box(5);
    popMatrix();
  }
  
  // HUD
  camera(); hint(DISABLE_DEPTH_TEST);
  fill(255); textSize(16);
  if (!lancee) {
     textAlign(CENTER); textSize(24);
     text("CLIQUER POUR LANCER", width/2, height/2);
  } else {
     textAlign(LEFT);
     text("Vitesse: " + (int)omega_phi + " rad/s", 20, 30);
     if(omega_phi < seuil_critique && omega_phi > 0) {
        fill(255, 100, 0); text("INSTABLE...", 20, 60);
     }
  }
  t+=dt;
  hint(ENABLE_DEPTH_TEST);
}

// --- FONCTIONS ---

void drawArena() {
  fill(60); 
  for (float r = 0; r < R_arene; r += 20) {
    float h1 = (float)(courbure * r * r);
    float h2 = (float)(courbure * (r+20) * (r+20));
    if((r/20)%2==0) fill(55); else fill(60);
    beginShape(QUAD_STRIP);
    for(int d=0; d<=360; d+=10) {
      float a = radians(d);
      vertex(cos(a)*r, sin(a)*r, h1);
      vertex(cos(a)*(r+20), sin(a)*(r+20), h2);
    }
    endShape();
  }
}

void drawCone(float r, float h, int sides) {
  float angle = TWO_PI / sides;
  beginShape(TRIANGLES);
  for (int i = 0; i < sides; i++) {
    float x1 = cos(angle * i) * r; float y1 = sin(angle * i) * r;
    float x2 = cos(angle * (i + 1)) * r; float y2 = sin(angle * (i + 1)) * r;
    vertex(0, 0, h); vertex(x1, y1, 0); vertex(x2, y2, 0);
  }
  endShape();
  beginShape(TRIANGLE_FAN); vertex(0, 0, 0);
  for (int i = sides; i >= 0; i--) vertex(cos(angle * i) * r, sin(angle * i) * r, 0);
  endShape();
}

void cylinder(float r, float h) {
  int sides = 30; float angle = TWO_PI / sides;
  beginShape(QUAD_STRIP);
  for (int i = 0; i <= sides; i++) {
    float x = cos(angle * i) * r; float y = sin(angle * i) * r;
    vertex(x, y, 0); vertex(x, y, h);
  }
  endShape();
  beginShape(TRIANGLE_FAN); vertex(0, 0, h); for (int i = 0; i <= sides; i++) vertex(cos(angle * i) * r, sin(angle * i) * r, h); endShape();
  beginShape(TRIANGLE_FAN); vertex(0, 0, 0); for (int i = sides; i >= 0; i--) vertex(cos(angle * i) * r, sin(angle * i) * r, 0); endShape();
}

void mousePressed() {
  lancee = true;
  
  float angle_depart = random(TWO_PI);
  x = cos(angle_depart) * 200;
  y = sin(angle_depart) * 200;
  
  float force = 4.0; 
  vx = -cos(angle_depart) * force + random(-1, 1);
  vy = -sin(angle_depart) * force + random(-1, 1);
  
  // Vitesse de rotation RÉDUITE (45 au lieu de 60-70)
  omega_phi = 45; 
  theta = 0.2;    
  omega_theta = 0;
}
