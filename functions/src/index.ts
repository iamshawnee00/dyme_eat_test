/**
 * Dyme Eat: The Legacy Engine - Cloud Functions (v2 SDK)
 *
 * This file contains the backend logic for aggregating reviews, awarding Influence Points (IP),
 * and managing other server-side tasks for the application, updated to use the Firebase Functions v2 SDK.
 */

// v2 Imports
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

// Legacy v1 import for functions.https.onCall
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

/**
 * ==========================================================================================
 * TASTE DIAL & REVIEW FUNCTIONS
 * ==========================================================================================
 */

/**
 * Triggered whenever a new review is written. It performs three main actions:
 * 1. Awards +25 IP to the author of the review.
 * 2. Triggers the aggregation of taste data for the associated restaurant.
 * 3. Checks if the user has met the criteria for the Revelation Event.
 */

export const onreviewcreated = onDocumentCreated("reviews/{reviewId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        logger.error("No data associated with the review event.");
        return;
    }
    const reviewData = snap.data();
    const { authorId, restaurantId } = reviewData;

    if (!authorId || !restaurantId) {
        logger.error("Review is missing authorId or restaurantId.");
        return;
    }

    const userRef = db.collection("users").doc(authorId);
    await userRef.update({
      influencePoints: admin.firestore.FieldValue.increment(25),
    });
    logger.log(`Awarded +25 IP to user ${authorId} for new review.`);

    await recalculateTasteSignature(restaurantId);
    await checkForRevelationEvent(authorId);
});

async function recalculateTasteSignature(restaurantId: string) {
    const restaurantRef = db.collection("restaurants").doc(restaurantId);
    const reviewsSnapshot = await db.collection("reviews").where("restaurantId", "==", restaurantId).get();

    if (reviewsSnapshot.empty) {
        logger.log(`No reviews for restaurant ${restaurantId}. Resetting signature.`);
        await restaurantRef.update({ overallTasteSignature: {} });
        return;
    }

    const signature: { [key: string]: number } = {};
    const counts: { [key: string]: number } = {};
    reviewsSnapshot.forEach((doc) => {
        const reviewData = doc.data();
        const tasteDialData = reviewData.tasteDialData as { [key: string]: number };
        if (tasteDialData) {
            for (const key in tasteDialData) {
                signature[key] = (signature[key] || 0) + tasteDialData[key];
                counts[key] = (counts[key] || 0) + 1;
            }
        }
    });

    const newTasteSignature: { [key: string]: number } = {};
    for (const key in signature) {
        newTasteSignature[key] = signature[key] / counts[key];
    }
    newTasteSignature._reviewCount = reviewsSnapshot.size;

    await restaurantRef.update({ overallTasteSignature: newTasteSignature,reviewCount: reviewsSnapshot.size, });
    logger.log(`Updated taste signature for restaurant ${restaurantId}`);
}


/**
 * ==========================================================================================
 * PATHFINDER TIP FUNCTIONS
 * ==========================================================================================
 */

/**
 * Triggered when a pathfinderTip document is updated (e.g., upvoted).
 * Checks if a tip has reached the verification threshold and awards IP if it has.
 */
export const onpathfindertipupdate = onDocumentUpdated("pathfinderTips/{tipId}", async (event) => {
    const snap = event.data;
    if (!snap) {
        logger.error("No data associated with the tip update event.");
        return;
    }
    const newData = snap.after.data();
    const oldData = snap.before.data();
    
    if (newData.upvotes === oldData.upvotes || newData.isVerified) {
        return;
    }

    const VERIFICATION_THRESHOLD = 3;
    if (newData.upvotes >= VERIFICATION_THRESHOLD) {
        const tipId = snap.after.id;
        const authorId = newData.authorId;
        if (!authorId) {
            logger.error(`Tip ${tipId} has no authorId.`);
            return;
        }
        await db.collection("pathfinderTips").doc(tipId).update({ isVerified: true });
        await db.collection("users").doc(authorId).update({
            influencePoints: admin.firestore.FieldValue.increment(15),
        });
        logger.log(`Tip ${tipId} verified. Awarded +15 IP to user ${authorId}.`);
    }
});


/**
 * ==========================================================================================
 * FOODIE PERSONALITY & REVELATION EVENT (NEW)
 * ==========================================================================================
 */

const REVELATION_THRESHOLD = 15; // Number of reviews needed to trigger the event

/**
 * Checks if a user has met the conditions for the Foodie Personality Revelation Event.
 * @param {string} userId The ID of the user to check.
 */
async function checkForRevelationEvent(userId: string) {
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  const userData = userDoc.data();

  // Stop if the user doesn't exist or their crest has already been revealed.
  if (!userData || userData.foodieCrestRevealed) {
    return;
  }

  // Count the number of reviews the user has submitted.
  const reviewsSnapshot = await db.collection("reviews").where("authorId", "==", userId).get();
    const reviewCount = reviewsSnapshot.size;
    logger.log(`User ${userId} has ${reviewCount} reviews.`);

    if (reviewCount >= REVELATION_THRESHOLD) {
        logger.log(`User ${userId} met revelation threshold. Analyzing...`);
        await analyzeAndAssignFoodiePersonality(userId, reviewsSnapshot);
    }
}

/**
 * Analyzes a user's review history to determine their 4-letter Foodie Personality,
 * awards them IP, and sets the `foodieCrestRevealed` flag.
 * @param {string} userId The user to analyze.
 * @param {FirebaseFirestore.QuerySnapshot} reviewsSnapshot The user's reviews.
 */
async function analyzeAndAssignFoodiePersonality(userId: string, reviewsSnapshot: FirebaseFirestore.QuerySnapshot) {
    const totals: { [key: string]: number } = {};
    const counts: { [key: string]: number } = {};

    reviewsSnapshot.forEach((doc) => {
        const tasteData = doc.data().tasteDialData as { [key: string]: number } || {};
        for (const key in tasteData) {
            totals[key] = (totals[key] || 0) + tasteData[key];
            counts[key] = (counts[key] || 0) + 1;
        }
    });

    const averages: { [key: string]: number } = {};
    for (const key in totals) {
        averages[key] = totals[key] / counts[key];
    }

    let personality = "";
    personality += (averages["Richness"] || 0) > (averages["Spiciness"] || 0) ? "R" : "S";
    const overallAverage = Object.values(averages).reduce((sum, val) => sum + val, 0) / (Object.keys(averages).length || 1);
    personality += overallAverage > 3.5 ? "I" : "M";
    personality += (averages["Sweetness"] || 0) > 3.0 ? "S" : "V";
    const allValues = reviewsSnapshot.docs.flatMap((doc) => Object.values(doc.data().tasteDialData || {}) as number[]);
    const variance = getVariance(allValues);
    personality += variance > 2.0 ? "B" : "N";

    await db.collection("users").doc(userId).update({
        foodiePersonality: personality,
        foodieCrestRevealed: true,
        influencePoints: admin.firestore.FieldValue.increment(500),
    });
    logger.log(`Revelation for user ${userId}! Personality: ${personality}. Awarded +500 IP.`);
}

function getVariance(numbers: number[]): number {
    if (numbers.length < 2) return 0;
    const mean = numbers.reduce((a, b) => a + b, 0) / numbers.length;
    return numbers.map((v) => (v - mean) ** 2).reduce((a, b) => a + b, 0) / numbers.length;
}  


/**
 * ==========================================================================================
 * RESTAURANT SUBMISSION FUNCTIONS (NEW)
 * ==========================================================================================
 */

/**
 * Triggered when a new restaurant suggestion is created.
 * This function currently serves as a placeholder for logging. The IP award
 * will happen when an admin approves the submission.
 */
export const onrestaurantsuggestioncreated = onDocumentCreated("submittedRestaurants/{submissionId}", (event) => {
    const submissionData = event.data?.data();
    if (submissionData) {
        logger.log("New restaurant suggestion received:", submissionData.name);
    }
});

export const onrestaurantsuggestionupdate = onDocumentUpdated("submittedRestaurants/{submissionId}", async (event) => {
    const snap = event.data;
    if (!snap) return;
    const newData = snap.after.data();
    const oldData = snap.before.data();

    if (newData.status === "approved" && oldData.status !== "approved") {
        const { name, address, location, city, state, submittedBy, cuisineTags } = newData;
        if (!submittedBy) {
            logger.error("Approved submission is missing 'submittedBy' UID.");
            return;
        }
        await db.collection("restaurants").add({
            name, address, location, city: city || "", state: state || "",
            cuisineTags: cuisineTags || [], overallTasteSignature: {},
            createdBy: submittedBy, createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        await db.collection("users").doc(submittedBy).update({
            influencePoints: admin.firestore.FieldValue.increment(100),
        });
        logger.log(`Approved restaurant '${name}'. Awarded +100 IP to user ${submittedBy}.`);
    }
});


// ==========================================================================================
// GROUP MODULE & STORY FUNCTIONS
// ==========================================================================================
export const creategroup = onCall(async (request) => {
    const uid = request.auth?.uid;
    const groupName = request.data.name;

    if (!uid) throw new HttpsError("unauthenticated", "You must be logged in to create a group.");
    if (!groupName || typeof groupName !== "string" || groupName.length > 50) {
        throw new HttpsError("invalid-argument", "Group name must be a string up to 50 characters.");
    }

    const groupRef = await db.collection("groups").add({
        name: groupName, createdBy: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        members: [uid], tasteSignature: {}, allergies: {},
    });
    return { groupId: groupRef.id };
});

/**
 * A callable function that adds a new member to a group.
 * The caller must be an existing member of the group.
 */
export const addMemberToGroup = onCall(async (request) => {
    const uid = request.auth?.uid;
    const { groupId, newUserEmail } = request.data;

    if (!uid) {
        throw new HttpsError("unauthenticated", "You must be logged in.");
    }
    if (!groupId || !newUserEmail) {
        throw new HttpsError("invalid-argument", "Group ID and new member's email are required.");
    }

    const groupRef = db.collection("groups").doc(groupId);
    const groupDoc = await groupRef.get();

    if (!groupDoc.exists) {
        throw new HttpsError("not-found", "Group not found.");
    }

    const groupData = groupDoc.data()!;
    // Security Check: Ensure the person making the request is already a member.
    if (!groupData.members.includes(uid)) {
        throw new HttpsError("permission-denied", "You are not a member of this group.");
    }

    // Find the new user by their email
    const newUserQuery = await db.collection("users").where("email", "==", newUserEmail).limit(1).get();
    if (newUserQuery.empty) {
        throw new HttpsError("not-found", `User with email ${newUserEmail} not found.`);
    }
    const newMemberId = newUserQuery.docs[0].id;

    // Add the new member's UID to the group's member list
    await groupRef.update({
        members: admin.firestore.FieldValue.arrayUnion(newMemberId),
    });

    return { success: true, message: "Member added successfully." };
});

/**
 * A callable function that analyzes a group's taste preferences and suggests a restaurant.
 */
export const getGroupRecommendation = onCall(async (request) => {
    const uid = request.auth?.uid;
    const { groupId } = request.data;

    if (!uid) throw new HttpsError("unauthenticated", "You must be logged in.");
    if (!groupId) throw new HttpsError("invalid-argument", "Group ID is required.");

    const groupDoc = await db.collection("groups").doc(groupId).get();
    if (!groupDoc.exists) throw new HttpsError("not-found", "Group not found.");

    const members = groupDoc.data()!.members as string[];
    if (!members.includes(uid)) {
        throw new HttpsError("permission-denied", "You are not a member of this group.");
    }
    if (members.length === 0) {
        throw new HttpsError("failed-precondition", "This group has no members.");
    }

    // --- Taste Analysis ---
    // 1. Fetch all reviews from all members of the group
    const reviewsSnapshot = await db.collection("reviews").where("authorId", "in", members).get();
    if (reviewsSnapshot.empty) {
        throw new HttpsError("not-found", "No reviews from group members to analyze.");
    }

    // 2. Aggregate all taste data
    const aggregatedTaste: { [key: string]: { total: number, count: number } } = {};
    reviewsSnapshot.forEach((doc) => {
        const review = doc.data();
        if (review.tasteDialData) {
            for (const [key, value] of Object.entries(review.tasteDialData as { [key: string]: number })) {
                if (!aggregatedTaste[key]) aggregatedTaste[key] = { total: 0, count: 0 };
                aggregatedTaste[key].total += value;
                aggregatedTaste[key].count += 1;
            }
        }
    });

    // 3. Find the flavor with the highest average rating
    let topFlavor = "";
    let highestAvg = -1;
    for (const [key, { total, count }] of Object.entries(aggregatedTaste)) {
        const avg = total / count;
        if (avg > highestAvg) {
            highestAvg = avg;
            topFlavor = key;
        }
    }

    if (!topFlavor) {
        throw new HttpsError("not-found", "Could not determine a top flavor for the group.");
    }

    // --- Restaurant Recommendation ---
    // Find a restaurant with a high score in the group's top flavor.
    const restaurantsSnapshot = await db.collection("restaurants")
        .orderBy(`overallTasteSignature.${topFlavor}`, "desc")
        .limit(1)
        .get();

    if (restaurantsSnapshot.empty) {
        throw new HttpsError("not-found", `No restaurants found that match the group's top flavor: ${topFlavor}.`);
    }
    
    const recommendedRestaurant = restaurantsSnapshot.docs[0].data();

    return {
        recommendation: {
            name: recommendedRestaurant.name,
            address: recommendedRestaurant.address,
            reason: `Highly rated for the group's favorite flavor: ${topFlavor}`,
        },
    };
});


export const onstorycreated = onDocumentCreated("stories/{storyId}", (event) => {
    const storyData = event.data?.data();
    if (storyData) {
        logger.log(`New story submitted for restaurant ${storyData.restaurantId} by user ${storyData.authorId}.`);
    }
});

/**
 * ==========================================================================================
 * FOODIE CARD FUNCTIONS (NEW)
 * ==========================================================================================
 */

/**
 * A callable function that generates the data payload for a user's Foodie Card.
 * This data can be used by the client to generate a QR code and display the card.
 */
export const generateFoodieCardData = onCall(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new HttpsError("unauthenticated", "You must be logged in.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
        throw new HttpsError("not-found", "User not found.");
    }
    const userData = userDoc.data()!;

    // --- Analyze reviews to find top flavors ---
    const reviewsSnapshot = await db.collection("reviews").where("authorId", "==", uid).get();
    
    const flavorCounts: { [key: string]: number } = {};
    reviewsSnapshot.forEach((doc) => {
        const review = doc.data();
        if (review.tasteDialData) {
            Object.keys(review.tasteDialData).forEach((key) => {
                flavorCounts[key] = (flavorCounts[key] || 0) + 1;
            });
        }
    });
    // Sort by frequency and get the top 3
    const topFlavors = Object.entries(flavorCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 3)
        .map(([key]) => key);

    // --- Construct the data payload ---
    const cardData = {
        userId: uid,
        name: userData.displayName || "N/A",
        crest: userData.foodiePersonality || "Not Revealed",
        ip: userData.influencePoints || 0,
        topFlavors: topFlavors,
    };

    // The client will stringify this JSON for the QR code
    return cardData;
});

export const generatepkpassdata = onCall(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Authentication required.");
    
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) throw new HttpsError("not-found", "User data not found.");
    
    const userData = userDoc.data()!;
    const reviewsSnapshot = await db.collection("reviews").where("authorId", "==", uid).get();
    const flavorCounts: { [key: string]: number } = {};
    reviewsSnapshot.forEach((doc) => {
        const tasteData = doc.data().tasteDialData as { [key: string]: number } || {};
        Object.keys(tasteData).forEach((key) => {
            flavorCounts[key] = (flavorCounts[key] || 0) + 1;
        });
    });
    const topFlavors = Object.entries(flavorCounts)
        .sort(([, a], [, b]) => b - a).slice(0, 3).map(([key]) => key);

    const passJson = {
        formatVersion: 1,
        passTypeIdentifier: "pass.com.dyme.eat.foodie-card",
        serialNumber: `DYME-${uid.substring(0, 10)}`,
        teamIdentifier: "YOUR_TEAM_ID",
        organizationName: "Dyme Eat",
        description: "Dyme Eat Foodie Card",
        logoText: "Dyme Eat",
        foregroundColor: "rgb(255, 255, 255)",
        backgroundColor: "rgb(30, 30, 30)",
        labelColor: "rgb(180, 180, 180)",
        storeCard: {
            primaryFields: [{ key: "name", label: "FOODIE", value: userData.displayName || "N/A" }],
            secondaryFields: [{ key: "crest", label: "FOODIE CREST", value: userData.foodiePersonality || "Not Revealed" }],
            auxiliaryFields: [{ key: "ip", label: "INFLUENCE", value: `${userData.influencePoints || 0} IP` }],
            backFields: [
                { key: "userId", label: "User ID", value: uid },
                { key: "topFlavors", label: "TOP FLAVORS", value: topFlavors.join(", ") || "Not yet rated" },
                { key: "info", label: "About", value: "This card represents your unique taste profile..." },
            ],
        },
        barcode: {
            message: JSON.stringify({ userId: uid }),
            format: "PKBarcodeFormatQR",
            messageEncoding: "iso-8859-1",
        },
    };

    return {
        success: true,
        message: "Pass data generated successfully.",
        downloadUrl: `https://your-pkpass-service.com/generate?data=${encodeURIComponent(JSON.stringify(passJson))}`,
    };
});



