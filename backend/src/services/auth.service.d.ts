export declare class AuthService {
    static registerUser(phoneNumber: string, fullName: string, nicheId: string): Promise<{
        user: any;
        token: string;
    }>;
    static loginUser(phoneNumber: string): Promise<{
        user: any;
        token: string;
    }>;
    private static generateToken;
}
//# sourceMappingURL=auth.service.d.ts.map