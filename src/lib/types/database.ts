export type MemberRole = "owner" | "admin" | "member";

type Profile = { id: string; email: string | null; full_name: string | null; created_at: string };
type Organization = { id: string; name: string; slug: string; created_by: string | null; created_at: string };
type Member = { id: string; organization_id: string; user_id: string; role: MemberRole; created_at: string };

export type Database = {
  public: {
    Tables: {
      profiles: {
        Row: Profile;
        Insert: Partial<Profile> & { id: string };
        Update: Partial<Profile>;
        Relationships: [];
      };
      organizations: {
        Row: Organization;
        Insert: Partial<Organization> & { name: string; slug: string };
        Update: Partial<Organization>;
        Relationships: [];
      };
      members: {
        Row: Member;
        Insert: Partial<Member> & { organization_id: string; user_id: string };
        Update: Partial<Member>;
        Relationships: [
          {
            foreignKeyName: "members_organization_id_fkey";
            columns: ["organization_id"];
            isOneToOne: false;
            referencedRelation: "organizations";
            referencedColumns: ["id"];
          },
          {
            foreignKeyName: "members_user_id_fkey";
            columns: ["user_id"];
            isOneToOne: false;
            referencedRelation: "profiles";
            referencedColumns: ["id"];
          },
        ];
      };
    };
    Views: Record<string, never>;
    Functions: {
      create_organization: {
        Args: { p_name: string; p_slug: string };
        Returns: Organization;
      };
    };
    Enums: { member_role: MemberRole };
    CompositeTypes: Record<string, never>;
  };
};
